MODULE sort_mod
!--------------------------!
! Quicksort subroutines for
! real and integer arrays
!--------------------------!
  USE def_mod, ONLY: wp
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: Iquicksort, Rquicksort

  CONTAINS

  RECURSIVE SUBROUTINE Iquicksort (Item, Order, First, Last)
  IMPLICIT NONE
  INTEGER, DIMENSION (:), INTENT(IN) :: Item
  INTEGER, DIMENSION (:), INTENT(INOUT) :: Order
  INTEGER, INTENT(IN) :: First, Last
  INTEGER :: Mid
  IF (First < Last) THEN                  ! If list size >= 2
     CALL Isplit(Item, Order, First, Last, Mid)  ! split it
     CALL Iquicksort(Item, Order, First, Mid-1)  ! sort left half
     CALL Iquicksort(Item, Order, Mid+1, Last)   ! sort right half
  END IF
  END SUBROUTINE


  SUBROUTINE Isplit(Item, Order, Low, High, Mid)
  IMPLICIT NONE
  INTEGER, DIMENSION (:), INTENT(IN) :: Item
  INTEGER, DIMENSION (:), INTENT(INOUT) :: order
  INTEGER, INTENT(IN) :: Low, High
  INTEGER, INTENT(OUT) :: Mid
  INTEGER :: Swap, Pivot
  INTEGER :: Left, Right

  Left = Low
  Right = High
  Pivot = Item(order(Low))

  ! Repeat the following while Left and Right haven't met
  DO
     IF (Left >= Right) EXIT

     ! Scan right to left to find element < Pivot
     DO
        IF (Left == Right .OR. Item(order(Right)) < Pivot) EXIT
        Right = Right - 1
     END DO

     ! Scan left to right to find element > Pivot
     DO
        IF (Left == Right .OR. Item(order(Left)) > Pivot) EXIT
        Left = Left + 1
     END DO

     ! If left and right haven't met, exchange the items
     IF (Left < Right) THEN
        Swap = order(Left)
        order(Left) = order(Right)
        order(Right) = Swap
     END IF
  END DO

  !Switch element in split position with pivot
  Swap = order(Low)
  order(Low) = order(Right)
  order(Right) = Swap
  Mid = Right

  END SUBROUTINE

  RECURSIVE SUBROUTINE Rquicksort (Item, Order, First, Last)
  IMPLICIT NONE
  REAL(wp), DIMENSION (:), INTENT(IN)    :: Item
  INTEGER,  DIMENSION (:), INTENT(INOUT) :: order
  INTEGER, INTENT(IN) :: First, Last
  INTEGER :: Mid
  IF (First < Last) THEN                  !If list size >= 2
     CALL Rsplit(Item, Order, First, Last, Mid)  ! split it
     CALL Rquicksort(Item, Order, First, Mid-1)  ! sort left half
     CALL Rquicksort(Item, Order, Mid+1, Last)   ! sort right half
  END IF
  END SUBROUTINE

  SUBROUTINE Rsplit(Item, Order, Low, High, Mid)
  IMPLICIT NONE
  REAL(wp), DIMENSION (:), INTENT(IN)    :: Item
  INTEGER,  DIMENSION (:), INTENT(INOUT) :: order
  REAL(wp) :: Pivot
  INTEGER, INTENT(IN) :: Low, High
  INTEGER, INTENT(OUT) :: Mid
  INTEGER :: Left, Right, Swap

  Left = Low
  Right = High
  Pivot = Item(order(Low))

  ! Repeat the following while Left and Right haven't met
  DO
     IF (Left >= Right) EXIT

     ! Scan right to left to find element < Pivot
     DO
        IF (Left == Right .OR. Item(order(Right)) < Pivot) EXIT
        Right = Right - 1
     END DO

     ! Scan left to right to find element > Pivot
     DO
        IF (Left == Right .OR. Item(order(Left)) > Pivot) EXIT
!        IF (Item(order(Left)) > Pivot) EXIT
        Left = Left + 1
     END DO

     ! If left and right haven't met, exchange the items
     IF (Left < Right) THEN
        Swap = order(Left)
        order(Left) = order(Right)
        order(Right) = Swap
     END IF
  END DO

  !Switch element in split position with pivot
  Swap = order(Low)
  order(Low) = order(Right)
  order(Right) = Swap
  Mid = Right

  END SUBROUTINE 

END MODULE
