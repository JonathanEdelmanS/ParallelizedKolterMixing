MODULE ssmat_mod
!------------------------!
! Utility subroutines for
! the data type ssmatrix
!------------------------!
USE def_mod

IMPLICIT NONE; PRIVATE
PUBLIC :: ssmat_alloc,   ssmat_null
PUBLIC :: ssmat_chkdiag, ssmat_getdiag

!Define type ssmatrix (sparse symmetric matrix) (in def_mod.f90)
!TYPE :: ssmatrix
!   INTEGER           :: size          ! Size of the matrix
!   INTEGER           :: nnz           ! Number of nonzeros
!   INTEGER,  POINTER :: ccol(:)       ! Compressed column column
!   INTEGER,  POINTER :: crow(:)       ! Compressed column row
!   REAL(wp), POINTER :: cval(:)       ! Compressed column value
!   INTEGER,  POINTER :: rrow(:)       ! Compressed row row
!   INTEGER,  POINTER :: rcol(:)       ! Compressed row column
!   REAL(wp), POINTER :: rval(:)       ! Compressed row value
!   REAL(wp)          :: sum           ! Sum of W values
!   REAL(wp)          :: norm1         ! 1-norm of vec(W)
!END TYPE ssmatrix

CONTAINS

!--------------------------------------------------
! Allocate object C of type(ssmatrix)
    SUBROUTINE ssmat_alloc(size, nnz, C)
      INTEGER, INTENT(IN) :: size, nnz
      TYPE (ssmatrix), INTENT(OUT) :: C
       C%size = size; C%nnz  = nnz
       ALLOCATE(C%ccol(size+1),C%crow(nnz),C%cval(nnz))
       ALLOCATE(C%rrow(size+1),C%rcol(nnz),C%rval(nnz))
    END SUBROUTINE ssmat_alloc

!--------------------------------------------------
! Deallocate object C of type(ssmatrix)
    SUBROUTINE ssmat_null(C)
      TYPE (ssmatrix), INTENT(INOUT) :: C
       C%size = 0; C%nnz = 0
       DEALLOCATE(C%ccol,C%crow,C%cval)
       DEALLOCATE(C%rcol,C%rrow,C%rval)
    END SUBROUTINE ssmat_null

!--------------------------------------------------
! Check if there exists a nonzero on diagonal of C
    FUNCTION ssmat_chkdiag(C) RESULT (nzdiag)
      TYPE (ssmatrix), INTENT(IN) :: C
      LOGICAL :: nzdiag
      INTEGER :: i, j, k
      nzdiag = .FALSE.
      DO j = 1, C%size
        DO k = C%ccol(j), C%ccol(j+1)-1
           i = C%crow(k)
           IF ( i == j ) THEN
              nzdiag = .TRUE.; RETURN
           END IF
        END DO
      END DO
    END FUNCTION ssmat_chkdiag

!--------------------------------------------------
! Extract the diagonal of object C of type(ssmatrix)
    FUNCTION ssmat_getdiag(C) RESULT (dC)
      TYPE (ssmatrix), INTENT(IN) :: C
      REAL(wp) :: dC (C%size)
      INTEGER :: i, j, k
      dC = zero
      DO j = 1, C%size
        DO k = C%ccol(j), C%ccol(j+1)-1
           i = C%crow(k)
           IF ( i == j ) dC(j) = C%cval(k)
        END DO
      END DO
    END FUNCTION ssmat_getdiag

END MODULE
