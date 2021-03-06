
#ifndef BL_SPACE_F_H
#define BL_SPACE_F_H

#include <SPACE.H>

#ifdef BL_LANG_FORT
#  if (BL_SPACEDIM == 1)

/*
  The DIM_V() macro can be used to enhance the portability of Fortran
  code.  It can be used whenever the BL_LANG_FORT preprocessor macro
  is defined.  It is used to specify the dimensionality of Fortran
  arrays, corresponding to BL_SPACEDIM.  lo and hi are
  BL_SPACEDIM-dimensional integer arrays that specify the low and
  high range of the array being specified.

  More explicitly, the macro evaluates to one of


     lo(1):hi(1)

     lo(1):hi(1),lo(2):hi(2)

     lo(1):hi(1),lo(2):hi(2),lo(3):hi(3)

  corresponding to BL_SPACEDIM values of 1, 2, or 3.
*/
#    define DIM_V(lo,hi) lo(1):hi(1)
#  elif (BL_SPACEDIM == 2)
#    define DIM_V(lo,hi) lo(1):hi(1),lo(2):hi(2)
#  elif (BL_SPACEDIM == 3)
#    define DIM_V(lo,hi) lo(1):hi(1),lo(2):hi(2),lo(3):hi(3)
#  endif
#endif

#endif /*BL_SPACE_F_H*/
