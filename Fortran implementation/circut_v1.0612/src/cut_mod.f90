MODULE cut_mod
!------------------------------------------
! Subroutines for generating partitions
!------------------------------------------
USE  def_mod
USE  get_mod
USE sort_mod

IMPLICIT NONE; PRIVATE
PUBLIC :: cut_circle,    &  ! find best cut for give t
          cut_eval,      &  ! evaluate cut value
          cut_locsch,    &  ! local search
          cut_random        ! a random cut

CONTAINS

!--------------------------------------------------
  SUBROUTINE cut_circle(t, x, cutval)
  IMPLICIT NONE
     REAL(wp), INTENT(IN)  :: t(W%size)  ! angular 
     INTEGER , INTENT(OUT) :: x(W%size)  ! binary
     REAL(wp), INTENT(OUT) :: cutval     ! cut value
! local variables
     INTEGER  :: i, j, k, index, ib, n1
     INTEGER  :: order(W%size+1), xtmp(W%size)
     REAL(wp) :: h, tmpval, cutang
     REAL(wp) :: tmp(W%size+1), wnodes(W%size,2)
     
     tmp(1:W%size) = modulo(t, 2*pi)
     tmp(W%size+1) = two*pi
     order = (/ (i, i = 1,W%size+1) /)
     CALL Rquicksort(tmp, order, 1, W%size+1)
     tmp = tmp(order)

    IF (param%task == 'cut') THEN
     ! initial cut
     x = 1
     DO k = W%size, 1, -1
        IF (tmp(k) > pi) THEN
           x(order(k)) = -1
        ELSE
           j = k+1; EXIT
        END IF
     END DO
     CALL cut_nodesums(x,wnodes)
     cutval = half * SUM(wnodes(:,1))
     tmpval = cutval; xtmp = x
     ! cut around the circle
     h = zero; i = 1
     DO 
        IF (tmp(i) <= tmp(j) - pi) THEN
           index = order(i); i = i + 1; h = tmp(i)
        ELSE
           index = order(j); j = j + 1; h = tmp(j) - pi
        END IF
        IF ( h > pi ) EXIT
        CALL cut_update(index, xtmp, tmpval, wnodes)
        IF ( tmpval > cutval ) THEN
           cutval = tmpval; x = xtmp; ib = index
        END IF
     END DO
    ELSE ! bisection
     n1 = W%size/2
     x(order(1:n1)) = 1
     x(order(n1+1:W%size)) = -1
     CALL cut_nodesums(x,wnodes)
     cutval = half * SUM(wnodes(:,1))
     tmpval = cutval; xtmp = x
     DO i = 1, n1
        index = order(i)             ! leaving
        CALL cut_update(index, xtmp, tmpval, wnodes)
        index = order(n1+i)          ! entering
        CALL cut_update(index, xtmp, tmpval, wnodes)
        IF ( tmpval > cutval ) THEN
           cutval = tmpval; x = xtmp; ib = index
        END IF
     END DO
!    cutang = modulo(t(ib), two*pi); !print*, cutang
    END IF

  END SUBROUTINE

!--------------------------------------------------
  SUBROUTINE cut_update(index, x, cutval, wnodes)
    IMPLICIT NONE
    INTEGER,  INTENT(IN)    :: index
    INTEGER,  INTENT(INOUT) :: x(W%size)
    REAL(wp), INTENT(INOUT) :: cutval
    REAL(wp), INTENT(INOUT) :: wnodes(W%size,2)
    INTEGER :: i, j, k
    REAL(wp) :: swap

! x(index) has changed side
    x(index) = -x(index)
    cutval = cutval + wnodes(index,2) - wnodes(index,1)
!   IF (ABS(cutval-cut_eval(x))>1.d-8) STOP 'Error in update'
    swap = wnodes(index,1)
    wnodes(index,1) = wnodes(index,2)
    wnodes(index,2) = swap
    CALL update_wnodes(index,x,W%ccol,W%crow,W%cval,wnodes)
    CALL update_wnodes(index,x,W%rrow,W%rcol,W%rval,wnodes)

  END SUBROUTINE

!----------------------------------------------------------
  SUBROUTINE update_wnodes(index,x,ivec1,ivec2,wvec,wnodes)
    IMPLICIT NONE
    INTEGER,  INTENT(IN)    :: index, x(W%size)
    INTEGER,  INTENT(IN)    :: ivec1(W%size+1)
    INTEGER,  INTENT(IN)    :: ivec2(W%nnz)
    REAL(wp), INTENT(IN)    :: wvec(W%nnz)
    REAL(wp), INTENT(INOUT) :: wnodes(W%size,2)
      INTEGER :: i, j, k, xij
       i = index  ! x(index) has changed side
       DO k = ivec1(i), ivec1(i+1) - 1
          j = ivec2(k); xij = x(i)*x(j)
          wnodes(j,1) = wnodes(j,1) - xij*wvec(k)
          wnodes(j,2) = wnodes(j,2) + xij*wvec(k)
       END DO
  END SUBROUTINE

!--------------------------------------------------
  SUBROUTINE cut_nodesums(x,wnodes)
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: x(W%size)
    REAL(wp), INTENT(INOUT) :: wnodes(W%size,2)
!             1st column -- sum of   cut weights
!             2nd column -- sum of uncut weights
    INTEGER :: i, j, k
    wnodes = zero
    DO j = 1, W%size   ! column sums
       DO k = W%ccol(j), W%ccol(j+1)-1
          i = W%crow(k)
          SELECT CASE ( x(i)*x(j) )
             CASE (-1); wnodes(j,1) = wnodes(j,1)  + W%cval(k)
             CASE (+1); wnodes(j,2) = wnodes(j,2)  + W%cval(k)
             CASE DEFAULT; STOP 'x must be +1 or -1'
          END SELECT
       END DO
    END DO
    DO i = 1, W%size   ! row sums
       DO k = W%rrow(i), W%rrow(i+1)-1
          j = W%rcol(k)
          SELECT CASE ( x(i)*x(j) ) 
             CASE (-1); wnodes(i,1) = wnodes(i,1)  + W%rval(k)
             CASE (+1); wnodes(i,2) = wnodes(i,2)  + W%rval(k)
             CASE DEFAULT; STOP 'x must be +1 or -1'
          END SELECT
       END DO
    END DO
  END SUBROUTINE

!--------------------------------------------------
  FUNCTION cut_random() RESULT (x)
      INTEGER  :: x(W%size), i
      REAL(wp) :: tmp(W%size)
      CALL get_random( tmp )
      x = 1
      DO i = 1, W%size
         IF ( tmp(i) < half ) x(i) = -1
      END DO
  END FUNCTION

!--------------------------------------------------
  FUNCTION cut_eval(x) RESULT (v)    ! eval cut value
    IMPLICIT NONE
    REAL(wp) :: v                    ! cut value
    INTEGER, INTENT(in) :: x(W%size) ! x_i = +1 or -1
    INTEGER :: i, j, k               ! loop variables
    v = zero
    DO j = 1, W%size   ! column sums
       DO k = W%ccol(j), W%ccol(j+1)-1
          i = W%crow(k)
          v = v + W%cval(k) * ( 1 - x(i)*x(j) )
       END DO
    END DO
    v = half * v 
  END FUNCTION

!----------------------------------------------------------
  SUBROUTINE cut_locsch(x,cutval)
    IMPLICIT NONE
    INTEGER,  INTENT(INOUT) :: x(W%size)
    REAL(wp), INTENT(INOUT) :: cutval
    REAL(wp) :: wnodes(W%size,2)
    INTEGER :: i, j, k
    LOGICAL :: done
       CALL cut_nodesums(x,wnodes)
       IF (param%task == 'cut') THEN
         done = .FALSE.
         DO WHILE (.NOT. done)
           done = .TRUE.
           DO i = 1, W%size
             IF (wnodes(i,1) + 0.01_wp < wnodes(i,2)) THEN
                 CALL cut_update(i,x,cutval,wnodes)
                 done = .FALSE.
                 IF (param%plevel > 1) PRINT*, '1-move to:', cutval
             END IF
           END DO
         END DO
       END IF
      !IF (param%task == 'bis') THEN
         done = .FALSE.
         DO WHILE (.NOT. done)
           done = .TRUE.
           DO i = 2, W%size
             DO k = W%rrow(i), W%rrow(i+1)-1
                j = W%rcol(k)
                IF (x(i)*x(j) < 0 .AND. wnodes(i,1)+wnodes(j,1)+0.1_wp < &
                   wnodes(i,2) + wnodes(j,2) + two*W%rval(k)) THEN
                   CALL cut_update(i,x,cutval,wnodes)
                   CALL cut_update(j,x,cutval,wnodes)
                   done = .FALSE.
                   IF (param%plevel > 1) PRINT*, '2-move to:', cutval
                END IF
             END DO
           END DO
         END DO
      !END IF
  END SUBROUTINE

END MODULE
