/* Includes for memory limit warnings.
   Copyright (C) 1990, 1993, 1994, 1995, 1996, 2001, 2002, 2003, 2004,
                 2005, 2006, 2007, 2008, 2009, 2010  Free Software Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.  */

#ifdef MSDOS
#include <dpmi.h>
extern int etext;
#endif

/* Some systems need this before <sys/resource.h>.  */
#include <sys/types.h>

#ifdef HAVE_SYS_RESOURCE_H
# include <sys/time.h>
# include <sys/resource.h>
#else
# if HAVE_SYS_VLIMIT_H
#  include <sys/vlimit.h>	/* Obsolete, says glibc */
# endif
#endif

#ifdef BSD4_2
#include <sys/time.h>
#include <sys/resource.h>
#endif /* BSD4_2 */

/* The important properties of this type are that 1) it's a pointer, and
   2) arithmetic on it should work as if the size of the object pointed
   to has a size of 1.  */
typedef POINTER_TYPE *POINTER;

typedef unsigned long SIZE;

#ifdef NULL
#undef NULL
#endif
#define NULL ((POINTER) 0)

extern POINTER start_of_data (void);
#if defined USE_LSB_TAG
#define EXCEEDS_LISP_PTR(ptr) 0
#elif defined DATA_SEG_BITS
#define EXCEEDS_LISP_PTR(ptr) \
  (((EMACS_UINT) (ptr) & ~DATA_SEG_BITS) >> VALBITS)
#else
#define EXCEEDS_LISP_PTR(ptr) ((EMACS_UINT) (ptr) >> VALBITS)
#endif

/* arch-tag: fe39244e-e54f-4208-b7aa-02556f7841c5
   (do not change this comment) */
