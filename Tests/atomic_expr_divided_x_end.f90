      RECURSIVE FUNCTION IS_POSSIBLE(subset, destination, length, init) RESULT(POSSIBLE)
        INTEGER, INTENT(IN) :: length
        REAL(8),DIMENSION(length), INTENT(IN) :: subset
        REAL(8), INTENT(IN) :: destination
        REAL(8), INTENT(IN) :: init
        REAL(8),ALLOCATABLE :: passed(:)
        LOGICAL :: POSSIBLE
        INTEGER :: x, y
        IF (length .gt. 0) THEN
          ALLOCATE(passed(length - 1))
        ELSE
          IF (abs(init - destination) .gt. PRECISION) THEN
            POSSIBLE = .TRUE.
          ELSE
            POSSIBLE = .FALSE.
          END IF
          RETURN
        END IF
        POSSIBLE = .FALSE.
        DO x = 1, length
          DO y = 1, x - 1
            passed(y) = subset(y)
          END DO
          DO y = x + 1, length
            passed(y - 1) = subset(y)
          END DO
          IF (IS_POSSIBLE(passed, destination, length - 1, subset(x) / init)) THEN
            POSSIBLE = .TRUE.
            RETURN
          END IF
        END DO
      END FUNCTION IS_POSSIBLE

      INTEGER FUNCTION test()
        IMPLICIT NONE
        INCLUDE "acc_testsuite.f90"
        INTEGER :: x, y !Iterators
        REAL(8),DIMENSION(LOOPCOUNT, 10):: a !Data
        REAL(8),DIMENSION(LOOPCOUNT):: totals
        REAL(8),DIMENSION(10):: passed
        INTEGER :: errors = 0
        LOGICAL IS_POSSIBLE

        !Initilization
        CALL RANDOM_SEED()
        CALL RANDOM_NUMBER(a)

        totals = 1

        !$acc data copyin(a(1:LOOPCOUNT, 1:10)) copy(totals(1:LOOPCOUNT))
          !$acc parallel
            !$acc loop
            DO x = 1, LOOPCOUNT
              DO y = 1, 10
                !$acc atomic
                  totals(x) = a(x, y) / totals(x)
                !$acc end atomic
              END DO
            END DO
          !$acc end parallel
        !$acc end data


        DO x = 1, LOOPCOUNT
          DO y = 1, 10
            passed(y) = a(x, y)
          END DO
          IF (IS_POSSIBLE(passed, totals(x), 10, 1) .eqv. .FALSE.) THEN
            errors = errors + 1
          END IF
        END DO
        test = errors
      END


      PROGRAM test_kernels_async_main
      IMPLICIT NONE
      INTEGER :: failed, success !Number of failed/succeeded tests
      INTEGER :: num_tests,crosschecked, crossfailed, j
      INTEGER :: temp,temp1
      INCLUDE "acc_testsuite.f90"
      INTEGER test


      CHARACTER*50:: logfilename !Pointer to logfile
      INTEGER :: result

      num_tests = 0
      crosschecked = 0
      crossfailed = 0
      result = 1
      failed = 0

      !Open a new logfile or overwrite the existing one.
      logfilename = "test.log"
!      WRITE (*,*) "Enter logFilename:"
!      READ  (*,*) logfilename

      OPEN (1, FILE = logfilename)

      WRITE (*,*) "######## OpenACC Validation Suite V 1.0a ######"
      WRITE (*,*) "## Repetitions:", N
      WRITE (*,*) "## Loop Count :", LOOPCOUNT
      WRITE (*,*) "##############################################"
      WRITE (*,*)

      WRITE (*,*) "--------------------------------------------------"
      !WRITE (*,*) "Testing acc_kernels_async"
      WRITE (*,*) "Testing test_kernels_async"
      WRITE (*,*) "--------------------------------------------------"

      crossfailed=0
      result=1
      WRITE (1,*) "--------------------------------------------------"
      !WRITE (1,*) "Testing acc_kernels_async"
      WRITE (1,*) "Testing test_kernels_async"
      WRITE (1,*) "--------------------------------------------------"
      WRITE (1,*)
      WRITE (1,*) "testname: test_kernels_async"
      WRITE (1,*) "(Crosstests should fail)"
      WRITE (1,*)

      DO j = 1, N
        temp =  test()
        IF (temp .EQ. 0) THEN
          WRITE (1,*)  j, ". test successfull."
          success = success + 1
        ELSE
          WRITE (1,*) "Error: ",j, ". test failed."
          failed = failed + 1
        ENDIF
      END DO


      IF (failed .EQ. 0) THEN
        WRITE (1,*) "Directive worked without errors."
        WRITE (*,*) "Directive worked without errors."
        result = 0
        WRITE (*,*) "Result:",result
      ELSE
        WRITE (1,*) "Directive failed the test ", failed, " times."
        WRITE (*,*) "Directive failed the test ", failed, " times."
        result = failed * 100 / N
        WRITE (*,*) "Result:",result
      ENDIF
      CALL EXIT (result)
      END PROGRAM
