MODULE def_mod
!-----------------------------------
! Define the working precision: wp,
! other constants, the symmetric
! sparse matrix data structure,
! and global variables
!-----------------------------------

IMPLICIT NONE; PRIVATE
PUBLIC :: wp, pi, zero, one, two, half, probname, rho
PUBLIC :: ssmatrix, W, param_type, param

INTEGER,  PARAMETER :: wp = SELECTED_REAL_KIND(8)
REAL(wp), PARAMETER :: pi = 3.14159265358979_wp
REAL(wp), PARAMETER :: zero = 0.0_wp
REAL(wp), PARAMETER :: one  = 1.0_wp
REAL(wp), PARAMETER :: two  = 2.0_wp
REAL(wp), PARAMETER :: half = 0.5_wp
CHARACTER(80)       :: probname
REAL(wp)            :: rho

! Define type ssmatrix (sparse symmetric matrix)
TYPE :: ssmatrix
   INTEGER           :: size          ! Size of the matrix
   INTEGER           :: nnz           ! Number of nonzeros
   INTEGER,  POINTER :: ccol(:)       ! Compressed column column
   INTEGER,  POINTER :: crow(:)       ! Compressed column row
   REAL(wp), POINTER :: cval(:)       ! Compressed column value
   INTEGER,  POINTER :: rrow(:)       ! Compressed row row
   INTEGER,  POINTER :: rcol(:)       ! Compressed row column
   REAL(wp), POINTER :: rval(:)       ! Compressed row value
   REAL(wp)          :: sum           ! Sum of W values
   REAL(wp)          :: norm1         ! 1-norm of vec(W)
END TYPE ssmatrix

! Define parameter type
TYPE :: param_type
   CHARACTER(3) :: obj
   CHARACTER(3) :: task
   INTEGER      :: plevel
   INTEGER      :: init
   INTEGER      :: npert
   INTEGER      :: multi
   REAL(wp)     :: tolf
   REAL(wp)     :: tolg
   REAL(wp)     :: pert
   REAL(wp)     :: rho
   INTEGER      :: maxiter
   REAL(wp)     :: maxstep
   LOGICAL      :: locsch
   LOGICAL      :: savecut
   LOGICAL      :: savesol
END TYPE param_type

! Define global variables
TYPE (ssmatrix)   :: W
TYPE (param_type) :: param

END MODULE
