module cc_rhs_module

    use BoxLib
    use ml_layout_module
    use multifab_module

    implicit none

contains

  subroutine cc_rhs(mla, pd, rh, rhs_type)

    type(ml_layout), intent(inout) :: mla
    type(box      ), intent(in   ) :: pd
    type( multifab), intent(inout) :: rh(:)
    integer        , intent(in   ) :: rhs_type

    integer                        :: n, dm, nlevs

    dm = mla%dim

    nlevs = mla%nlevel

    do n = nlevs, 1, -1
       call setval(rh(n), val = 0.d0, all=.true.)
    end do

    if (rhs_type .eq. 1) then
       call mf_init_1(rh(nlevs),pd)
    else if (rhs_type .eq. 2) then
       call mf_init_2(rh(nlevs),pd)
    else if (rhs_type .eq. 3) then
       call mf_init_3(rh(nlevs),pd)
    else if (rhs_type .eq. 4) then
       call mf_init_sins(rh(nlevs),pd)
    end if

  end subroutine cc_rhs

  subroutine mf_init_1(mf,pd)

    type(multifab), intent(inout) :: mf
    type(box)     , intent(in   ) :: pd
    type(box) :: bx

    bx = pd
    bx%lo(1:bx%dim) = (bx%hi(1:bx%dim) + bx%lo(1:bx%dim))/4
    bx%hi(1:bx%dim) = bx%lo(1:bx%dim)
    call setval(mf, 1.d0, bx)

    call print(bx,'Setting to 1 here ')

    bx = pd
    bx%lo(1:bx%dim) = 3*(bx%hi(1:bx%dim) + bx%lo(1:bx%dim))/4
    bx%hi(1:bx%dim) = bx%lo(1:bx%dim)
    call setval(mf, -1.d0, bx)

    call print(bx,'Setting to -1 here ')

  end subroutine mf_init_1

  subroutine mf_init_2(mf,pd)

    type(multifab), intent(inout) :: mf
    type(box     ), intent(in   ) :: pd

    integer   :: i
    type(box) :: bx

    do i = 1, nfabs(mf)

       bx = get_box(mf,i)
       bx%lo(1:bx%dim) = (bx%hi(1:bx%dim) + bx%lo(1:bx%dim))/2
       bx%hi(1:bx%dim) = bx%lo(1:bx%dim)
       call setval(mf%fbs(i), 1.0_dp_t, bx)
!       print *,'SETTING RHS TO 1.d0 ON ',bx%lo(1:bx%dim)

!      Single point of non-zero RHS: use this to make system solvable
       bx = get_box(mf,i)
       bx%lo(1       ) = (bx%hi(1       ) + bx%lo(1       ))/2 + 1
       bx%lo(2:bx%dim) = (bx%hi(2:bx%dim) + bx%lo(2:bx%dim))/2
       bx%hi(1:bx%dim) = bx%lo(1:bx%dim)
       call setval(mf%fbs(i), -1.0_dp_t, bx)
!       print *,'SETTING RHS TO -1.d0 ON ',bx%lo(1:bx%dim)

!      1-d Strip: Variation in x-direction
!      bx%lo(1) = (bx%hi(1) + bx%lo(1))/2
!      bx%hi(1) = bx%lo(1)+1

!      1-d Strip: Variation in y-direction
!      bx%lo(2) = (bx%hi(2) + bx%lo(2))/2
!      bx%hi(2) = bx%lo(2)+1

!      1-d Strip: Variation in z-direction
!      bx%lo(3) = (bx%hi(3) + bx%lo(3))/2
!      bx%hi(3) = bx%lo(3)+1

    end do
  end subroutine mf_init_2

  subroutine mf_init_3(mf,pd)

    type(multifab), intent(inout) :: mf
    type(box     )  , intent(in   ) :: pd

    integer   :: i
    type(box) :: bx, rhs_box, rhs_intersect_box

    rhs_box%dim = mf%dim
    rhs_box%lo(1:rhs_box%dim) = 7
    rhs_box%hi(1:rhs_box%dim) = 8

    do i = 1, nfabs(mf)
       bx = get_ibox(mf,i)
       rhs_intersect_box = box_intersection(bx,rhs_box)
       if (.not. empty(rhs_intersect_box)) then
         bx%lo(1:bx%dim) = lwb(rhs_intersect_box)
         bx%hi(1:bx%dim) = upb(rhs_intersect_box)
!         print *,'SETTING RHS IN BOX ',i,' : ', bx%lo(1:bx%dim),bx%hi(1:bx%dim)
         call setval(mf%fbs(i), 1.d0, bx)
       end if
    end do

  end subroutine mf_init_3

  subroutine mf_init_sins(mf,pd)

    type(multifab)  , intent(inout) :: mf
    type(box     )  , intent(in   ) :: pd

    type(box)                :: bx
    real(kind=dp_t)          :: dx
    real(kind=dp_t), pointer :: rp(:,:,:,:)

    integer   :: i,dm,nx,ny

    nx = pd%hi(1) - pd%lo(1) + 1
    ny = pd%hi(2) - pd%lo(2) + 1

    if (nx .ne. ny) then
       print *,'Not sure what to do with nx .neq. ny in mf_init_sins'
       stop
    end if

    dx = 1.d0 / dble(nx)
 
    dm = mf%dim

    print *,'Setting rhs to a sum of sins '
    do i = 1, nfabs(mf)
       bx = get_ibox(mf, i)
       rp => dataptr(mf,i,bx)
       if (dm.eq.2) then
          call init_sin_2d(rp(:,:,1,1),bx,dx)
       else if (dm.eq.3) then 
          call init_sin_3d(rp(:,:,:,1),bx,dx)
       end if
    end do

  end subroutine mf_init_sins

  subroutine init_sin_2d(rhs,bx,dx)

      type(box)       , intent(in   ) :: bx
      double precision, intent(inout) :: rhs(bx%lo(1):,bx%lo(2):)
      double precision, intent(in   ) :: dx

      integer :: i,j
      double precision :: tpi, epi, spi
      double precision :: x, y

      tpi = 8.d0 * datan(1.d0)

      do j = bx%lo(2),bx%hi(2)
      do i = bx%lo(1),bx%hi(1)
         x = (dble(i)+0.5d0) * dx
         y = (dble(j)+0.5d0) * dx
         rhs(i,j) = sin(tpi*x) + sin(tpi*y)
      end do
      end do

  end subroutine init_sin_2d

  subroutine init_sin_3d(rhs,bx,dx)

      type(box)       , intent(in   ) :: bx
      double precision, intent(inout) :: rhs(bx%lo(1):,bx%lo(2):,bx%lo(3):)
      double precision, intent(in   ) :: dx

      integer :: i,j,k
      double precision :: tpi, epi, spi
      double precision :: x, y, z

      tpi = 8.d0 * datan(1.d0)
      epi =  4.d0 * tpi
      spi = 16.d0 * tpi

      do k = bx%lo(3),bx%hi(3)
      do j = bx%lo(2),bx%hi(2)
      do i = bx%lo(1),bx%hi(1)
         x = (dble(i)+0.5d0) * dx
         y = (dble(j)+0.5d0) * dx
         z = (dble(k)+0.5d0) * dx
         rhs(i,j,k) = sin(tpi*x) + sin(tpi*y) + sin(tpi*z)
      end do
      end do
      end do

  end subroutine init_sin_3d

end module cc_rhs_module