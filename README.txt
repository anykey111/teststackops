
Translate the math expression to the Forth notation using only stack shuffle.
The first number is an estimated complexity.

Running from command line

    % a b c -- x
    swipl -s stackops -g 'juggle([a,b,c],a*a+b*b+c,X)'
    21,[dup,*,over,rot,*,+,swap,+]
    23,[dup,*,swap,tuck,rot,*,+,swap,+]
    23,[dup,swap,*,over,rot,*,+,swap,+]
    25,[dup,swap,*,swap,tuck,rot,*,+,swap,+]

    % a b c -- x
    swipl -s stackops -g 'juggle([a,b,c],a*a+b*b*2+c,X)'
    25,[dup,*,over,rot,*,2,*,+,swap,+]
    27,[dup,*,swap,tuck,rot,*,2,*,+,swap,+]
    27,[dup,swap,*,over,rot,*,2,*,+,swap,+]
    29,[dup,swap,*,swap,tuck,rot,*,2,*,+,swap,+]

    % a b -- x
    swipl -s stackops -g 'juggle([a,b],a+b*a,X)'
    9,[tuck,*,+]
    11,[swap,over,*,+]
    ...

    % b a -- x
    ?- juggle([b,a],a*b+a*b,X).
    7,[*,dup,+]
    9,[*,dup,swap,+]
    11,[swap,swap,*,dup,+]
    ...
