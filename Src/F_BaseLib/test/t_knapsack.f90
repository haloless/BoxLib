subroutine t_knapsack
  use bl_IO_module
  use f2kcli
  use boxarray_module
  use box_util_module
  use knapsack_module
  use list_box_module
  integer :: un, np, n, idm
  real(kind=dp_t) :: thresh
  integer :: verbose
  integer, allocatable :: iweights(:), prc(:)
  real(kind=dp_t) :: maxprc, minprc, xmean, stddev
  real(kind=dp_t), allocatable :: weights(:)
  integer :: i
  character(len=128) fname
  type(boxarray) :: ba
  type(box) :: bx

  if ( command_argument_count() < 1 ) then
     np = 128
  else
     call get_command_argument(1, value = fname)
     read(fname,*) np
  end if

  print*, 'np = ', np

!  call read_a_mglib_grid_ba(ba, bx, '../../data/mglib_grids/grids.5034')
  call read_a_mglib_grid_ba(ba, bx, '../../data/mglib_grids/grids.1071')

  if (contains(ba,ba)) then
     print*, 'ba contains ba'
  else
     print*, 'ba does NOT contain ba'
  endif

  if (contains(ba,bx)) then
     print*, 'ba contains empty bx'
  else
     print*, 'ba does NOT contain empty bx'
  endif

  n = nboxes(ba)

  allocate(iweights(n))
  do i = 1, n
     iweights(i) = volume(get_box(ba,i))
  end do

  allocate(prc(n))

  verbose = 1; thresh = 1.0_dp_t

  call knapsack_i(prc, iweights, ba%bxs, np, verbose, thresh)

  call destroy(ba)

end subroutine t_knapsack


