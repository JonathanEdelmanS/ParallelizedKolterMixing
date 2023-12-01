PROGRAM main  
!-------------!
! Main Program
!-------------!
 USE   def_mod
 USE ssmat_mod
 USE   get_mod
 USE   opt_mod
 USE   cut_mod
 IMPLICIT NONE

 !TYPE(ssmatrix) :: W        ! defined in def_mod
 !TYPE(param_type) :: param  ! defined in def_mod
 INTEGER , ALLOCATABLE :: x(:), xb(:)
 REAL(wp), ALLOCATABLE :: t(:), g(:), dH(:), tb(:)
 INTEGER :: size, nnz, i, j, k, tcount, time(8), sgn, xsum
 REAL(wp):: f, timer(2), tprocess, bsfval, cutval, bestcut, avgcut
 CHARACTER(40) :: filename, param_file
 CHARACTER(80) :: Fmt = '(1X, A, F10.3," sec.")'

 ! Get parameters
     timer(1) = get_time(zero)   ! for elapsed time
     OPEN(7,file='param.file',status='OLD',action='READ',iostat=i)
     IF (i /= 0) STOP 'Main: cannot open param.file'
     READ(7,'(A)') param_file    ! get param file name
     CALL get_param(param_file)  ! get parameter values
     CALL get_version            ! print version number
     WRITE(*,'(1X,A)') 'Enter file name (RETURN to quit): '

   Repeat: DO ! solve different problems

 ! Pre-process
     READ (*,'(A)',IOSTAT=i) filename
     IF (i /= 0 .OR. filename == '') EXIT
     timer(2) = get_time(zero)
     bestcut=-HUGE(one)
     CALL pre_process
     tprocess = get_time(timer(2))

 ! Multi-starts
     avgcut = zero
     Multi_start: DO k = 1, param%multi
        CALL driver
        avgcut = avgcut + bsfval
     END DO Multi_start
     avgcut = avgcut / param%multi

 ! Post-process
     CALL post_process
     timer(2) = get_time(timer(2))
     WRITE(*,Fmt) 'process time:', tprocess
     WRITE(*,Fmt) 'total   time:', timer(2); WRITE(*,*)

   END DO Repeat
 
   timer(1) = get_time(timer(1))
   WRITE(*,*) '---------------------------'
   WRITE(*,Fmt) 'Elapsed Time:', timer(1)

 CONTAINS

!----------------------------------------------------!
     SUBROUTINE pre_process
     i = SCAN(filename,"/", BACK=.TRUE.)
     IF (i < 0) i = 0
     probname = filename(i+1:); sgn = 1
     CALL get_size(filename, size, nnz)
     CALL ssmat_alloc(size, nnz, W)
     CALL get_weights(filename, W)
     IF (param%obj == 'min') THEN
         W%cval = -W%cval; W%rval = -W%rval; sgn = -sgn
     END IF
     ALLOCATE(t(size),g(size),dH(size),x(size),xb(size),tb(size))
     WRITE(*,'(1X,"<",A,"> n =",I6,", m =",I8)') &
           TRIM(probname), size, nnz
     IF (param%rho > zero) rho = param%rho * MAXVAL(ABS(W%cval))
     END SUBROUTINE

!----------------------------------------------------!
     SUBROUTINE driver
     bsfval = -HUGE(one); tcount = 0
     CALL get_init(t, param%init)

     Restart: DO  !while tcount <= param%npert

        CALL opt_solver( t, f, g, dH )
        CALL cut_circle( t, x, cutval )
        IF (param%locsch) CALL cut_locsch( x, cutval )

        IF ( cutval > bsfval ) THEN
           IF (param%plevel == 1) WRITE(*,'(/1X,A,F14.2,1X)', &
               ADVANCE='no') 'cutval = ', sgn*cutval
           bsfval = cutval; tcount = 1
           IF ( bsfval > bestcut ) THEN
              bestcut = bsfval; xb = x; tb = t;
           END IF
        ELSE
           IF (param%plevel == 1) &
           WRITE(*,'(A)',ADVANCE='no') '*'
           tcount = tcount + 1
        END IF
        IF (param%plevel > 1) WRITE(*,'(1X,A,F14.2)') &
            TRIM(probname)//' cutval: ', sgn*bsfval

        IF (tcount > param%npert) EXIT
        CALL get_random( t )
        t = param%pert*(two*pi*t-pi) + (half*pi)*(1-x)

     END DO Restart

     END SUBROUTINE

!----------------------------------------------------!
     SUBROUTINE post_process

     IF (param%plevel == 1) WRITE(*,*)
     IF (param%locsch) CALL cut_locsch( xb, bestcut )
     WRITE(*,'(1X,A,A,F12.2,A,F12.2)') '<'//TRIM(probname)//'>',&
          ' bestcut: ', sgn*bestcut, ' meancut: ', sgn*avgcut
     WRITE(*,'(A,4X,A)') ' problem type: ', param%obj//param%task  
     xsum = SUM(xb)
     IF (param%task=='bis' .AND. xsum /= 0) &
         WRITE(*,*) ' sum(x) =  ', xsum
     IF ( param%savecut ) THEN
        filename=TRIM(probname)//'_'//param%obj//param%task//'.cut'
        OPEN(8, FILE = filename, ACTION = 'write')
        WRITE(8,*) size, nnz, sgn*bestcut
        WRITE(8,'(I2)') xb
        CLOSE(8)
     END IF
     IF ( param%savesol ) THEN
        tb = MODULO( tb, two*pi )
        filename=TRIM(probname)//'_'//param%obj//param%task//'.sol'
        OPEN(8, FILE = filename, ACTION = 'write')
        WRITE(8,'(F12.4)') tb
        CLOSE(8)
     END IF
     CALL ssmat_null(W); DEALLOCATE(t,g,dH,x,xb,tb)
     END SUBROUTINE

END PROGRAM main
