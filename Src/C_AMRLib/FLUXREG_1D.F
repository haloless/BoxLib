
#undef  BL_LANG_CC
#ifndef BL_LANG_FORT
#define BL_LANG_FORT
#endif

#include "REAL.H"
#include "CONSTANTS.H"
#include "FLUXREG_F.H"
#include "ArrayLim.H"

#define SDIM 1

c ::: -----------------------------------------------------------
c ::: Add fine grid flux to flux register.  Flux array is a fine grid
c ::: edge based object, Register is a coarse grid edge based object.
c ::: It is assumed that the coarsened flux region contains the register
c ::: region.
c :::
c ::: INPUTS/OUTPUTS:
c ::: reg       <=> edge centered coarse grid flux register
c ::: DIMS(reg)  => index limits for reg
c ::: flx        => edge centered fine grid flux array
c ::: DIMS(flx)  => index limits for flx
c ::: numcomp    => number of components to update
c ::: dir        => direction normal to flux register
c ::: ratio(2)   => refinement ratios between coarse and fine
c ::: mult       => scalar multiplicative factor
c ::: -----------------------------------------------------------

      subroutine FORT_FRFINEADD(reg,DIMS(reg),flx,DIMS(flx),
     &                          numcomp,dir,ratio,mult)

      implicit none

      integer    DIMDEC(reg)
      integer    DIMDEC(flx)
      integer    ratio(1), dir, numcomp
      REAL_T     mult
      REAL_T     reg(DIMV(reg),numcomp)
      REAL_T     flx(DIMV(flx),numcomp)

      integer    n, i, ic
      integer    ratiox

      ratiox = ratio(1)

      if (dir .eq. 0) then
c        ::::: flux normal to X direction
         ic = ARG_L1(reg)
         i = ic*ratiox
         if (ARG_L1(reg) .ne. ARG_H1(reg)) then
            call bl_abort("FORT_FRFINEADD: bad register direction")
         end if
         if (i .lt. ARG_L1(flx) .or. i .gt. ARG_H1(flx)) then
            call bl_abort("FORT_FRFINEADD: index outside flux range")
         end if
         do n = 1, numcomp
            reg(ic,n) = reg(ic,n) + mult*flx(i,n)
         end do
      end if

      end

c ::: -----------------------------------------------------------
c ::: Add fine grid flux times area to flux register.
c ::: Flux array is a fine grid edge based object, Register is a
c ::: coarse grid edge based object.
c ::: It is assumed that the coarsened flux region contains the register
c ::: region.
c :::
c ::: INPUTS/OUTPUTS:
c ::: reg       <=> edge centered coarse grid flux register
c ::: rlo,rhi    => index limits for reg
c ::: flx        => edge centered fine grid flux array
c ::: DIMS(flx)  => index limits for flx
c ::: area       => edge centered area array
c ::: DIMS(area) => index limits for area
c ::: numcomp    => number of components to update
c ::: dir        => direction normal to flux register
c ::: ratio(2)   => refinements ratio between coarse and fine
c ::: mult       => scalar multiplicative factor
c ::: -----------------------------------------------------------

      subroutine FORT_FRFAADD(reg,DIMS(reg),flx,DIMS(flx),area,DIMS(area),
     &                        numcomp,dir,ratio,mult)

      implicit none

      integer    DIMDEC(reg)
      integer    DIMDEC(flx)
      integer    DIMDEC(area)
      integer    ratio(1), dir, numcomp
      REAL_T     mult
      REAL_T     reg(DIMV(reg),numcomp)
      REAL_T     flx(DIMV(flx),numcomp)
      REAL_T     area(DIMV(area))

      integer    n, i, ic
      integer    ratiox

      ratiox = ratio(1)

      if (dir .eq. 0) then
c        ::::: flux normal to X direction
         ic = ARG_L1(reg)
         i = ic*ratiox
         if (ARG_L1(reg) .ne. ARG_H1(reg)) then
            call bl_abort("FORT_FRFAADD: bad register direction")
         end if
         if (i .lt. ARG_L1(flx) .or. i .gt. ARG_H1(flx)) then
            call bl_abort("FORT_FRFAADD: index outside flux range")
         end if
         do n = 1, numcomp
            reg(ic,n) = reg(ic,n) + mult*area(i)*flx(i,n)
         end do
      end if

      end

c ::
c :: --------------------------------------------------------------
c :: reflux:   reflux the data on the outer boundary of
c ::           a fine grid.
c ::
c :: Inputs/Outputs
c :: s           <=>  state data array
c :: slo,shi      =>  index limits of s array
c :: vol          =>  volume array
c :: vlo,vhi      =>  index limits of vol array
c :: reg          =>  flux register
c :: rlo,rhi      =>  index limits of reg array
c :: lo,hi        =>  subregion of s array to be updated
c :: numcomp      =>  number of components to update
c :: mult         =>  multiplative factor (+1 or -1 depending on nomal)
c :: --------------------------------------------------------------
c ::
      subroutine FORT_FRREFLUX (s,DIMS(s),vol,DIMS(vol),reg,DIMS(reg),
     &                          lo,hi,shft,numcomp,mult)

      implicit none

      integer    DIMDEC(s)
      integer    DIMDEC(vol)
      integer    DIMDEC(reg)
      integer    lo(SDIM), hi(SDIM), shft(SDIM)
      integer    numcomp
      REAL_T     mult
      REAL_T     reg(DIMV(reg),numcomp)
      REAL_T       s(DIMV(s),numcomp)
      REAL_T     vol(DIMV(vol))

      integer n, i, ilo

      ilo = shft(1)

      do n = 1, numcomp
         do i = lo(1), hi(1)
            s(i-ilo,n) = s(i-ilo,n) + mult*reg(i,n)/vol(i-ilo)
         end do
      end do

      end

c ::: -----------------------------------------------------------
c ::: Add flux register into coarse grid flux (opposite of standard reflux ops)
c :::
c ::: INPUTS/OUTPUTS:
c ::: flx        => flux array
c ::: DIMS(flx)  => index limits for flx
c ::: reg       <=  flux register
c ::: DIMS(reg)  => index limits for reg
c ::: lo,hi      => region of update
c ::: mult       => scalar multiplicative factor
c ::: -----------------------------------------------------------

      subroutine FORT_SCALADDTO (flx,DIMS(flx),area,DIMS(area),reg,DIMS(reg),
     $                           lo,hi,numcomp,mult)

      implicit none

      integer    DIMDEC(flx)
      integer    DIMDEC(area)
      integer    DIMDEC(reg)
      integer    lo(SDIM), hi(SDIM)
      integer    numcomp
      REAL_T     mult
      REAL_T     flx(DIMV(flx),numcomp)
      REAL_T     area(DIMV(area))
      REAL_T     reg(DIMV(reg),numcomp)

      integer    n, i, istart

      if (area(lo(1)) .lt. 1.d-8) then
        do n = 1, numcomp
           flx(lo(1),n) = flx(lo(1),n)
        end do
        istart = lo(1)+1
      else
        istart = lo(1)
      end if

      do n = 1, numcomp
        do i = istart, hi(1)
          flx(i,n) = flx(i,n) + mult*reg(i,numcomp)/area(i)
        end do
      end do

      end
