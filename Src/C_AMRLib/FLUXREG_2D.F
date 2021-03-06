
#undef  BL_LANG_CC
#ifndef BL_LANG_FORT
#define BL_LANG_FORT
#endif

#include "REAL.H"
#include "CONSTANTS.H"
#include "FLUXREG_F.H"
#include "ArrayLim.H"

#define SDIM 2

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
      integer    ratio(2), dir, numcomp
      REAL_T     mult
      REAL_T     reg(DIMV(reg),numcomp)
      REAL_T     flx(DIMV(flx),numcomp)

      integer    n, i, j, ic, jc, off
      integer    ratiox, ratioy

      ratiox = ratio(1)
      ratioy = ratio(2)

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
            do off = 0, ratioy-1
               do jc = ARG_L2(reg), ARG_H2(reg)
                  j = ratioy*jc + off
                  reg(ic,jc,n) = reg(ic,jc,n) + mult*flx(i,j,n)
               end do
            end do
         end do
      else
c        ::::: flux normal to Y direction
         jc = ARG_L2(reg)
         j = jc*ratioy
         if (ARG_L2(reg) .ne. ARG_H2(reg)) then
            call bl_abort("FORT_FRFINEADD: bad register direction")
         end if
         if (j .lt. ARG_L2(flx) .or. j .gt. ARG_H2(flx)) then
            call bl_abort("FORT_FRFINEADD: index outside flux range")
         end if
         do n = 1, numcomp
            do off = 0, ratiox-1
               do ic = ARG_L1(reg), ARG_H1(reg)
                  i = ratiox*ic + off
                  reg(ic,jc,n) = reg(ic,jc,n) + mult*flx(i,j,n)
               end do
            end do
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
      integer    ratio(2), dir, numcomp
      REAL_T     mult
      REAL_T     reg(DIMV(reg),numcomp)
      REAL_T     flx(DIMV(flx),numcomp)
      REAL_T     area(DIMV(area))

      integer    n, i, j, ic, jc, off
      integer    ratiox, ratioy

      ratiox = ratio(1)
      ratioy = ratio(2)

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
            do off = 0, ratioy-1
               do jc = ARG_L2(reg), ARG_H2(reg)
                  j = ratioy*jc + off
                  reg(ic,jc,n) = reg(ic,jc,n) + mult*area(i,j)*flx(i,j,n)
               end do
            end do
         end do
      else
c        ::::: flux normal to Y direction
         jc = ARG_L2(reg)
         j = jc*ratioy
         if (ARG_L2(reg) .ne. ARG_H2(reg)) then
            call bl_abort("FORT_FRFAADD: bad register direction")
         end if
         if (j .lt. ARG_L2(flx) .or. j .gt. ARG_H2(flx)) then
            call bl_abort("FORT_FRFAADD: index outside flux range")
         end if
         do n = 1, numcomp
            do off = 0, ratiox-1
               do ic = ARG_L1(reg), ARG_H1(reg)
                  i = ratiox*ic + off
                  reg(ic,jc,n) = reg(ic,jc,n) + mult*area(i,j)*flx(i,j,n)
               end do
            end do
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

      integer n, i, j, ilo, jlo

      ilo = shft(1)
      jlo = shft(2)

      do n = 1, numcomp
         do j = lo(2), hi(2)
            do i = lo(1), hi(1)
               s(i-ilo,j-jlo,n) = s(i-ilo,j-jlo,n) + 
     &              mult*reg(i,j,n)/vol(i-ilo,j-jlo)
            end do
         end do
      end do

      end
