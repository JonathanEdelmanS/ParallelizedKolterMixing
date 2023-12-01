MODULE opt_mod
!-----------------------------------------------------------
! This module contains the continuous optimization functions 
!      opt_solver    --- the main solver routine
!      opt_backtrack --- backtracking line search
!      opt_fgdh      --- function, gradient, diag(Hessian)
!      opt_f         --- function evaluation only
!-----------------------------------------------------------
USE  def_mod
USE  get_mod

IMPLICIT NONE; PRIVATE
PUBLIC :: opt_solver, opt_backtrack, opt_fgdh, opt_f

  CONTAINS

!----------------------------------------------------------!
   SUBROUTINE opt_solver( t, f, g, dH )
     REAL(wp), INTENT(INOUT) :: t(W%size)
     REAL(wp), INTENT(OUT)   :: f, g(W%size), dH(W%size)
     REAL(wp):: fp, fchange, obj, grnrm, alpha
     REAL(wp):: dt(W%size)
     INTEGER :: iter, nback = 1

     f = HUGE(f); alpha = one
     DO iter = 0, param%maxiter
       fp = f
       CALL opt_fgdh(t, f, g, dH)
       obj = half * ( W%sum - f ) 
       grnrm = DOT_PRODUCT(g,g)/W%norm1
       fchange = abs(f-fp)/(one + abs(fp))

       IF (param%plevel > 1 .AND. mod(iter,1) == 0) &
           WRITE(*,10) iter,obj,grnrm,alpha
       IF (fchange < param%tolf .OR. grnrm < param%tolg) EXIT
       dt = -g / MAX(one, dH)
       CALL opt_backtrack(alpha,nback,t,dt,f,g)
       t = t + alpha * dt; !t = MODULO(t, two*pi)
       IF ( nback <= 2 ) alpha = MIN(param%maxstep, 2*alpha)
     END DO
     obj = half * ( W%sum - f ) 
     IF (param%plevel > 1) WRITE(*,10) iter,obj,grnrm,alpha
     10 FORMAT(' iter',I5,':  obj =', E16.8, &
               '  gn =',E10.3,'  alpha =',F7.4)

   END SUBROUTINE

!----------------------------------------------------------!
   SUBROUTINE opt_backtrack(alpha,nback,t,dt,f,g)
     REAL(wp), INTENT(INOUT) :: alpha  ! steplength
     INTEGER,  INTENT(OUT)   :: nback  ! No. of cutbacks
     REAL(wp), INTENT(IN)    :: t(W%size), dt(W%size)
     REAL(wp), INTENT(IN)    :: f, g(W%size)
   ! local variables
     REAL(wp) :: fnew, gTdt, gamma = .01_wp, tau = half;
     INTEGER  :: maxbacks = 10

     gTdt = DOT_PRODUCT(g,dt)
     if ( gTdt >= 0 ) STOP 'Not a descent direction'
     DO nback = 1, maxbacks
       fnew = opt_f( t + alpha * dt )
       IF ( fnew <= f + gamma * alpha * gTdt ) EXIT
       alpha = tau * alpha
     END DO
     IF (param%plevel > 1 .AND. nback == maxbacks ) &
        WRITE(*,*) 'Number of cutbacks = ', maxbacks
   END SUBROUTINE

!--------------------------------------------------
  SUBROUTINE opt_fgdh(t,f,g,dH)
    IMPLICIT NONE
    REAL(wp), INTENT(IN)  :: t(W%size)
    REAL(wp), INTENT(OUT) :: f, g(W%size),  dH(W%size)
    REAL(wp)              :: p, gp(W%size), dHp(W%size)
    REAL(wp)              :: cost(W%size), sint(W%size)
    REAL(wp)              :: sumcost,      sumsint
    INTEGER               :: i, j, k

    cost = COS(t); sint = SIN(t)
    g = zero; dH = zero
    DO j = 1, W%size   ! column sums
       DO k = W%ccol(j), W%ccol(j+1)-1
          i = W%crow(k)
          g(j)  = g(j)  + W%cval(k)*(sint(i)*cost(j)-cost(i)*sint(j))
          dH(j) = dH(j) - W%cval(k)*(cost(i)*cost(j)+sint(i)*sint(j))
       END DO
    END DO
    DO i = 1, W%size   ! row sums
       DO k = W%rrow(i), W%rrow(i+1)-1
          j = W%rcol(k)
          g(i)  =  g(i) - W%rval(k)*(sint(i)*cost(j)-cost(i)*sint(j))
          dH(i) = dH(i) - W%rval(k)*(cost(i)*cost(j)+sint(i)*sint(j))
       END DO
    END DO
    f = - half * SUM(dH)

    IF (param%task=='cut' .OR. param%rho <= zero) RETURN
    sumsint = SUM(sint); sumcost = SUM(cost)
    gp  = sumsint*cost - sumcost*sint
    dHp = one - (sumcost*cost + sumsint*sint)
    p  = - half * SUM(dHp)
    f  = rho * p   + f
    g  = rho * gp  + g
    dH = rho * dHp + dH

  END SUBROUTINE

!--------------------------------------------------
  FUNCTION opt_f(t) RESULT (f)
    IMPLICIT NONE
    REAL(wp) :: f, p
    REAL(wp), INTENT(IN) :: t(W%size)
    REAL(wp) :: cost(W%size), sint(W%size)
    REAL(wp) :: sumcost,      sumsint
    INTEGER :: i, j, k
    cost = COS(t); sint = SIN(t)
    f = zero
    DO j = 1, W%size   ! column sums
       DO k = W%ccol(j), W%ccol(j+1)-1
          i = W%crow(k)
          f = f + W%cval(k) * (cost(i)*cost(j)+sint(i)*sint(j))
       END DO
    END DO

    IF (param%task=='cut' .OR. param%rho <= zero) RETURN
    sumsint = SUM(sint); sumcost = SUM(cost)
    p = half * (sumcost**2 + sumsint**2 - W%size)
    f = rho * p + f

   END FUNCTION

END MODULE
