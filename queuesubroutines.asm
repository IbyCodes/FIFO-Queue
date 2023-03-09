// Mohammad Khan 
// Date: November 24, 2022

define(base_address_r, x19)                                             // defining queue base address
define(i_r, w20)                                                        // macro for i in display subroutine                                    
define(j_r, w21)                                                        // macro for j in display subroutine
define(count_r,w22)                                                     // macro for count in display subroutine 
QUEUESIZE = 8                                                           // defining global variables
FALSE = 0
TRUE = 1
MODMASK = 0x7


                .data                                                   // declaring external variables and aligning properly
head:           .word   -1                                              // initially -1
tail:           .word   -1                                              // initially -1
               
                .bss
mainQueue:      .skip   QUEUESIZE * 4    

                .text


                                                                                            // all strings needed to print somewhere in the program
stringqueueoverflow: .string "\nQueue overflow! Cannot enqueue into a full queue.\n"
stringqueueunderflow: .string "\nQueue underflow! Cannot dequeue from an empty queue.\n"
stringemptyqueue: .string "\nEmpty queue\n"
stringcurrentqueuecontents: .string "\nCurrent queue contents:\n"
stringhead: .string " <-- head of queue"
stringtail: .string " <-- tail of queue"
stringnewline: .string "\n"
stringinsertelement: .string "%d"

                                                                            // alignment and adding global tag to all subroutines
                .balign 4
                .global enqueue
                .global dequeue
                .global queueFull
                .global queueEmpty
                .global display
                

                
                
                fp .req x29                                                  // we can rename x29 as fp
                lr .req x30                                                // we can rename x30 as lr 


define(value_r, w9)                                                         // macro for value_r in enqueue (temporary)
define(tail_r, w10)                                                         // macro for the tail_r in enqueue (temp)
enqueue:                                                                    // enqueue subroutine
                stp     fp, lr, [sp, -16]!                                  // allocate memory
                mov     fp, sp                                              // update frame pointer
                mov     value_r, w0                                         // move the value of w0 into the register
                bl      queueFull                                           // branch and link the result of queueFull
                cmp     w0, FALSE                                           
                b.eq    ifqueueemptytest                                    // if the queue is not full, go to the next check of if queue is empty

ifqueuefull:                                                                // if the queue is indeed full then:
                adrp    x0, stringqueueoverflow                             // adding first argument 
                add     x0, x0, :lo12:stringqueueoverflow                   // we will print that the queue is full (overflow)
                bl      printf                                              // calling print function
                b       done1                                               // branching to done1 (skip through rest of enqueue code)

ifqueueemptytest:                                                       // test to see if the queue is empty
                bl      queueEmpty                                      // branch and link result of queueEmpty
                cmp     w0, FALSE                                       
                b.eq    ifnotemptyorfull                                 // if the queue is not empty, then it is also not full, so we can skip to ifnotemptyorfull

ifqueueempty:                                                           // if the queue is indeed empty then:
                adrp    base_address_r, head                            // getting the base address of the head
                add     base_address_r, base_address_r, :lo12:head      // formatting bits
                str     wzr, [base_address_r]                           // clearing the base address
                adrp    base_address_r, tail                            // getting the base address of the tail
                add     base_address_r, base_address_r, :lo12:tail      // formatting bits
                str     wzr, [base_address_r]                           // clearing the base address again
                b       enqueue_body                                    // branching to the body of the enqueue (code always ran whenever enqueue is called upon)                  


ifnotemptyorfull:                                                       // else statement under if(queueEmpty())

                adrp    base_address_r, tail                            // get base address of tail
                add     base_address_r, base_address_r, :lo12:tail      // formatting bits

                ldr     tail_r, [base_address_r]                            // Load the tail
                add     tail_r, tail_r, 1                                   // tail ++
                and     tail_r, tail_r, MODMASK                             // tail++ & MODMASK
                str     tail_r, [base_address_r]                            //store the tail                                                                             
                                                                                

enqueue_body:                                                               //queue[tail] = value 
                ldr     tail_r, [base_address_r]                            // loading the tail
                adrp    base_address_r, mainQueue                           // getting the base address of the queue
                add     base_address_r, base_address_r, :lo12:mainQueue     // formatting the bits
                str     value_r, [base_address_r, tail_r, SXTW 2]           // storing the value 

done1:
                                                                                    
                ldp     fp, lr, [sp], 16                                    // deallocating memory
                ret                                                         // returning to caller




define(value_r, w11)                                                    // macros for dequeue subroutine (temp)
define(head_r, w12)
define(tail_r, w13)    
dequeue:                                                                // dequeue subroutine
                stp     fp, lr, [sp, -16]!                              // allocating space             
                mov     fp, sp                                          // updating frame pointer
                bl      queueEmpty                                      // branching and linking result of queueEmpty
                cmp     w0, FALSE                                       
                b.eq    skipqueueempty                                  // if the queue is not empty, then we can go to the next part of the code

                adrp    x0, stringqueueunderflow                        // here, the queue is empty, so preparing string argument
                add     x0, x0, :lo12:stringqueueunderflow              // formatting bits
                bl      printf                                          // calling print function
                mov     w0, -1                                          // return -1
                b       done2                                           // branching to done2 (skipping all other dequeue function code)

skipqueueempty:                                                         // if the queue is not empty
                adrp    base_address_r, head                            // load the head base address
                add     base_address_r, base_address_r, :lo12:head      // format bits
                ldr     head_r, [base_address_r]                        // load head

                adrp    base_address_r, mainQueue                       // get base address of the queue
                add     base_address_r, base_address_r, :lo12:mainQueue   // format bits
                ldr     value_r, [base_address_r, head_r, SXTW 2]           //load the value

                adrp    base_address_r, tail                                // get the base address of the tail
                add     base_address_r, base_address_r, :lo12:tail           // format bits
                ldr     tail_r, [base_address_r]                            // load the tail

                cmp     head_r, tail_r                                      // compare the head and the tail
                b.ne    ifheadandtailne                                     // if the head and tail values are not the same, branch to ifheadandtailne

                                                                        // IF THE HEAD AND TAIL ARE THE SAME:
                mov     w22, -1                                         // w22 = -1 (temp register)
                adrp    base_address_r, head                            // get base address of the head
                add     base_address_r, base_address_r, :lo12:head         // format bits
                str     w22, [base_address_r]                           // store w22 into base_address_r of head
                adrp    base_address_r, tail                            // get base address of the tail
                add     base_address_r, base_address_r, :lo12:tail        // format bits
                str     w22, [base_address_r]                           // store w22 into base_address_r of tail
                b       done2                                           // branch to done2


                
                
                                                                // if head != tail:
ifheadandtailne:                                                

                add     head_r, head_r, 1                           // head++
                and     head_r, head_r, MODMASK                     // head++ & MODMASK
                adrp    base_address_r, head                         // get base address of the head
                add     base_address_r, base_address_r, :lo12:head     // format bits
                str     head_r, [base_address_r]                        // store head value, where head = ++head & MODMASK



done2:  
                mov         w0, value_r                            // w0 = value
                ldp         fp, lr, [sp], 16                        // dellocating memory
                ret                                                  // returning to caller



define(head_r, w14)                                                 // macros for queueFull subroutine (temp)
define(tail_r, w15)                
queueFull:                                                         // queueFull subroutine
                stp         fp, lr, [sp, -16]!                      // allocating memory
                mov         fp, sp                                  // updating the frame pointer


                adrp        base_address_r, tail                    // getting the base address of the tail
                add         base_address_r, base_address_r, :lo12:tail  // formatting bits
                ldr         tail_r, [base_address_r]                    // loading the value of tail

                add         tail_r, tail_r, 1                           //tail ++
                and         tail_r, tail_r, MODMASK                     // tail+1 & MODMASK

                adrp        base_address_r, head                        // getting the base address of the head
                add         base_address_r, base_address_r, :lo12:head  // formatting the bits
                ldr         head_r, [base_address_r]                    // loading the head value
                cmp         tail_r, head_r                              
                b.eq        isTrue1                                     // if tail == head, go to isTrue1
                mov         w0, FALSE                                  // else, return FALSE
                b done3                                                 // go to done3

isTrue1:        mov         w0, TRUE                                    // if tail == head, return TRUE

done3:

                ldp         fp, lr, [sp], 16                            // deallocate memory
                ret                                                     // return to caller


define(head_r, w19)                                                 // head_r macro for queueEmpty (temp)
queueEmpty:                                                         // queueEmpty subroutine 
                stp         fp, lr, [sp, -16]!                      // allocate memory
                mov         fp, sp                                  // update frame pointer
                adrp        base_address_r, head                    // load the base address of the head
                add         base_address_r, base_address_r, :lo12:head  // format bits
                ldr         head_r, [base_address_r]                   // load the head value
                cmp         head_r, -1                                 
                b.eq        isTrue2                                     // if head == -1 then branch to isTrue2
                mov         w0, FALSE                                   // else, return FALSE
                b           done4                                       // branch to done4

isTrue2:
                mov         w0, TRUE                                    // return TRUE if head == -1

done4:
                ldp         fp, lr, [sp], 16                            // deallocate memory
                ret                                                     // return to caller


                                                                        // registers for display to use (temp)
define(tail_r, w23)
define(head_r, w24)              
display:                                                                // display subroutine
                stp         fp, lr, [sp, -16]!                          // allocate memory
                mov         fp, sp                                      // update frame pointer
                bl          queueEmpty                                  // branch and link result of queueEmpty
                cmp         w0, FALSE                           
                b.eq        skipqueueempty2                            // if the queue is not empty, skip it's code
                adrp        x0, stringemptyqueue                        // if the queue is empty, want to print the string
                add         x0, x0, :lo12:stringemptyqueue              // format bits
                bl          printf                                      // calling the print function
                b           done5                                       // branch to done5 (skip all other display code)


skipqueueempty2:                                                        // if the queue is not empty

                adrp        base_address_r, head                        // getting the base address of the head
                add         base_address_r, base_address_r, :lo12:head  // formatting bits
                ldr         head_r, [base_address_r]                    // loading the value of the head 

                adrp        base_address_r, tail                        // getting the base address of the tail
                add         base_address_r, base_address_r, :lo12:tail  // formatting bits
                ldr         tail_r, [base_address_r]                    // loading the value of the tail

                sub         count_r, tail_r, head_r                     // count = tail - head 
                add         count_r, count_r, 1                         // count = tail - head + 1

               cmp          count_r, 0                      
               b.gt         bodyofdisplay                               // if count > 0, then branch to body of display
               add          count_r, count_r, QUEUESIZE                 // else, count<=0, so count += QUEUESIZE

bodyofdisplay:
               adrp         x0, stringcurrentqueuecontents              // loading the first argument (to print the current queue contents)
               add          x0, x0, :lo12:stringcurrentqueuecontents    // formatting bits
               bl           printf                                      // calling the print function to print the current queue contents
                
               
               mov          i_r, head_r                                 // initialzing i = head
               mov          j_r, 0                                      // initializing j = 0
               b            looptest                                    // branching to the for loop test


forloop:   
              adrp          x0, stringinsertelement                    // loading the first argument (value of the element)   
              add           x0, x0, :lo12:stringinsertelement          // formatting bits
              adrp          base_address_r, mainQueue                  // getting the base address of the main queue itself
              add           base_address_r, base_address_r, :lo12:mainQueue   // formatting bits
              ldr           w1, [base_address_r, i_r, SXTW 2]               // loading the value of queue[i]
              bl            printf                                          // calling the print function

              cmp           i_r, head_r                            
              b.ne          inehead                                   // if i != head, then skip i==head code
              adrp          x0, stringhead                              // else, we want to print its the head of the queue (loading argument)
              add           x0, x0, :lo12:stringhead                    // formatting bits
              bl            printf                                      // calling the print function

inehead:                                                          // if i != head
              cmp           i_r, tail_r                             
              b.ne          loopbody                                       // if i != tail then branch to loopbody (its not the tail of the queue)
              adrp          x0, stringtail                             // else, we want to print its the tail of the queue (loading argument)
              add           x0, x0, :lo12:stringtail                    // formatting bits
              bl            printf                                      // calling print function

loopbody:                                                          // printf("\n") and i = ++i & MODMASK code:

             adrp    x0, stringnewline                            // to print ("\n") (loading first argument)
             add     x0, x0, :lo12:stringnewline                // formatting bits
             bl      printf                                     // calling print function

             add     i_r, i_r, 1                             // i++
             and     i_r, i_r, MODMASK                       // i++ & MODMASK

             add     j_r, j_r, 1                             // must increment j at the very end of the loop, so j++

looptest:                                                   // looptest to test if j < count before looping through code again

             cmp     j_r, count_r                           
             b.lt    forloop                                // if j < count , then can continue to run code inside for loop. Else, finish.


done5:
            ldp     fp, lr, [sp], 16                        // deallocate memory
            ret                                             // return to main
