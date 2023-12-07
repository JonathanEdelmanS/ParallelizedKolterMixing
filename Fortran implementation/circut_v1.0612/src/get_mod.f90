MODULE get_mod
!------------------------------------------
! Subroutines for inputting data and for
! performing some other tasks
!------------------------------------------
USE  def_mod
USE sort_mod

IMPLICIT NONE; PRIVATE
PUBLIC :: get_size, get_weights, get_init, get_x
PUBLIC :: get_time, get_random, get_param, get_version

CONTAINS

!--------------------------------------------------
  SUBROUTINE get_size(filename, size, nnz)
    IMPLICIT NONE
    CHARACTER(*), INTENT(IN)  :: filename
    INTEGER,      INTENT(OUT) :: size, nnz
    INTEGER :: status
    OPEN (unit = 3, file = filename, status = 'old', &
          action = 'read', iostat = status)
    IF (status /= 0) STOP 'get_size: cannot open file'
    READ  (3,*) size, nnz
    CLOSE (unit = 3)
  END SUBROUTINE

!--------------------------------------------------
  SUBROUTINE get_weights(filename, W)
    IMPLICIT NONE
    CHARACTER(*),   INTENT(IN)    :: filename ! data file name
    TYPE(ssmatrix), INTENT(INOUT) :: W        ! weight matrix
    INTEGER,     DIMENSION(W%nnz) :: col, row ! column/row indices
    REAL(wp),    DIMENSION(W%nnz) :: val      ! values
    INTEGER,     DIMENSION(W%nnz) :: order    ! for quicksort
    INTEGER :: i,j,k                          ! loop variables

  ! get data from file
    CALL get_data(filename, col, row, val)

  ! sort by column (compressed column storage)
    order = (/(i, i = 1,W%nnz)/)
    DO i = 1, W%nnz-1
       IF ( col(i) > col(i+1) ) THEN  ! not sorted
          IF (param%plevel > 1) WRITE(*,*) 'Sorting the column ......'
          CALL Iquicksort(col, order, 1, W%nnz)
          EXIT
       END IF
    END DO
    W%crow = row(order)
    W%cval = val(order)
    j = col(order(1))  ! nonzero column starts here
    W%ccol(1:j) = 1 
    DO i = 2, W%nnz
       k = col(order(i)) - col(order(i-1))
       IF ( k > 0 ) THEN
          W%ccol(j+1:j+k) = i; j = j + k; 
       END IF
    END DO
    W%ccol(j+1:W%size+1) = W%nnz + 1

  ! sort by row (compressed row storage)
    order = (/(i, i = 1, W%nnz)/)
    DO i = 1, W%nnz-1
       IF ( row(i) > row(i+1) ) THEN  ! not sorted
          IF (param%plevel > 1) WRITE(*,*) 'Sorting the row ......'
          CALL Iquicksort(row, order, 1, W%nnz)
          EXIT
       END IF
    END DO
    W%rcol = col(order)
    W%rval = val(order)
    j = row(order(1))  ! nonzero row starts here
    W%rrow(1:j) = 1 
    DO i = 2, W%nnz
       k = row(order(i)) - row(order(i-1))
       IF ( k > 0 ) THEN
          W%rrow(j+1:j+k) = i; j = j + k; 
       END IF
    END DO
    W%rrow(j+1:W%size+1) = W%nnz + 1

    W%sum = SUM(W%cval)
    W%norm1 = SUM(ABS(W%cval))

  END SUBROUTINE

!--------------------------------------------------
  SUBROUTINE get_data(filename, col, row, val)
    IMPLICIT NONE
    CHARACTER(*), INTENT(IN) :: filename !filename of matrix data
    INTEGER, INTENT(OUT) :: col(W%nnz)   ! Column indices
    INTEGER, INTENT(OUT) :: row(W%nnz)   ! Row indices
    REAL(wp),INTENT(OUT) :: val(W%nnz)   ! Values
    INTEGER :: i                         ! local variable
    OPEN (unit = 3, file = filename, status = 'old', & 
          action = 'read', iostat = i)
    IF (i /= 0) STOP 'get_data: cannot open file'
    READ(3,*) ! skip the 1st line
    DO i = 1, W%nnz
       READ(3,*) row(i), col(i), val(i)
    END DO
    CLOSE (unit = 3)
  END SUBROUTINE

!----------------------------------------------------------!
   SUBROUTINE get_init(t, init)
!  Initialize t: (0) equ-distributed  in (0, 2*pi)
!                (1) uniformly random in (0, 2*pi)
!                (2) perturbation from a cut
      REAL(wp), INTENT(INOUT) :: t(W%size)
      INTEGER,  INTENT(IN)    :: init
      CHARACTER(80) :: initcut_file
      INTEGER  :: i, x(W%size)
      IF (init == 0) THEN
         t = (/(i, i=1,W%size)/)*(two*pi/W%size)
         RETURN
      ELSE
         CALL get_random( t )
         t = (two*pi)*t
         IF (init == 1) RETURN
      END IF
   !  for init == 2
      initcut_file = TRIM(probname)//'_'//param%obj//param%task//'.ini'
      CALL get_x( initcut_file, x )
      t = param%pert*(t-pi) + (half*pi)*(1-x)
   END SUBROUTINE

!----------------------------------------------------------!
   SUBROUTINE get_x(filename, x)
      CHARACTER(*), INTENT(IN) :: filename
      INTEGER, INTENT(OUT) :: x(W%size)
      INTEGER :: i
      OPEN (unit = 9, file = filename, status = 'old', & 
            action = 'read', iostat = i)
      IF (i /= 0) STOP "get_x: cannot open file"
      READ(9,*)  ! skip the 1st line
      DO i = 1, W%size 
         READ(9,*) x(i)
      END DO
      CLOSE (unit = 9)
   END SUBROUTINE

!-----------------------------------------------!
  FUNCTION get_time(tic) RESULT (toc)  ! in second
     REAL(wp), INTENT(IN) :: tic
     REAL(wp) :: toc
     INTEGER  :: time(8)
     CALL DATE_AND_TIME( VALUES = time )
     toc = 3600.0_wp*time(5) + 60.0_wp*time(6) &
            + one*time(7) + time(8)/1000.0_wp - tic
     IF ( toc < 0 ) toc = toc + 24.0_wp*3600
  END FUNCTION

!-----------------------------------------------!
  SUBROUTINE get_random(t)
     REAL(wp), INTENT(INOUT) :: t(:)

     INTEGER :: i, n, clock
     INTEGER, DIMENSION(:), ALLOCATABLE :: seed
          
     CALL RANDOM_SEED(size = n)
     ALLOCATE(seed(n))
          
     CALL SYSTEM_CLOCK(COUNT=clock)
          
     seed = clock + 37 * (/ (i - 1, i = 1, n) /)
     CALL RANDOM_SEED(PUT = seed)
          
     DEALLOCATE(seed)

     CALL RANDOM_NUMBER( t )
  END SUBROUTINE

!----------------------------------------------------------!
  SUBROUTINE get_param(filename)
     CHARACTER(*) :: filename
     INTEGER :: i
     OPEN(3,file=filename,status='OLD',action='READ',iostat=i)
     IF (i /= 0) STOP 'get_param: cannot open file'
     READ(3,'(A)')   param%obj
     READ(3,'(A)')   param%task
     READ(3,*)       param%plevel
     READ(3,*)       param%init
     READ(3,*)       param%npert
     READ(3,*)       param%multi
     READ(3,*)       param%tolf
     READ(3,*)       param%tolg
     READ(3,*)       param%pert
     READ(3,*)       param%rho
     READ(3,*)       param%maxiter
     READ(3,*)       param%maxstep
     READ(3,'(L1)')  param%locsch
     READ(3,'(L1)')  param%savecut
     READ(3,'(L1)')  param%savesol
     CLOSE(3)
  END SUBROUTINE

!----------------------------------------------------------!
  SUBROUTINE get_version
     WRITE(*,*)
     WRITE(*,'(12X, A)') '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
     WRITE(*,'(12X, A)') '%                                          %'
     WRITE(*,'(12X, A)') '%         CirCut  Version 1.0612           %'
     WRITE(*,'(12X, A)') '%     Yin Zhang, CAAM, Rice University     %'
     WRITE(*,'(12X, A)') '%                                          %'
     WRITE(*,'(12X, A)') '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
     WRITE(*,*)
  END SUBROUTINE

END MODULE