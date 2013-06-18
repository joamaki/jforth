\ Core forth words

: IF IMMEDIATE
  ' 0BRANCH ,
  HERE @	\ save offset to stack
  0 ,           \ compile dummy offset
;

: THEN IMMEDIATE
  DUP
  HERE @ SWAP . \ calc offset
  SWAP !        \ store offset
;

: ELSE IMMEDIATE
  ' BRANCH ,
  HERE @	\ save offset to stack
  0 ,  		\ compile dummy offset
  SWAP
  DUP
  HERE @ SWAP .
  SWAP !
;

: BEGIN IMMEDIATE
  HERE @	\ save location
;

: UNTIL IMMEDIATE
  ' 0BRANCH ,	
  HERE @ -
  ,
;

: AGAIN IMMEDIATE
  ' BRANCH ,
  HERE @ -
  ,
;

: WHILE IMMEDIATE
  ' 0BRANCH ,
  HERE @
  0 ,
;

: REPEAT IMMEDIATE
  ' BRANCH ,
  SWAP
  HERE @ - ,
  DUP
  HERE @ SWAP -
  SWAP !
;

: [COMPILE] IMMEDIATE
  WORD
  FIND
  >CFA
  ,
;

: UNLESS IMMEDIATE
  ' NOT ,
  [COMPILE] IF
;

: ( IMMEDIATE
  1 \ depth
  BEGIN
	KEY
	DUP '(' =IF
	    DROP
	    1+
	ELSE
		')' = IF
		    1- \ closing paren, decrease depth
		THEN
	THEN
  DUP 0= UNTIL \ loop until depth 0
  DROP
;

