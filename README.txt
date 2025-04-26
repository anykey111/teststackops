
Translate the math expression to the Forth notation using only stack shuffle.
The first number is an estimated complexity.

Running from command line

    % a b c -- x
    swipl -s stackops -g 'juggle([a,b,c],a*a+b*b+c,X)'
    21,[+,swap,+,*,rot,over,*,dup]
    23,[+,swap,+,*,rot,over,*,swap,dup]
    23,[+,swap,+,*,rot,tuck,swap,*,dup]
    25,[+,swap,+,*,rot,tuck,swap,*,swap,dup]

    % a b c -- x
    swipl -s stackops -g 'juggle([a,b,c],a*a+b*b*2+c,X)'
    25,[+,swap,+,*,2,*,rot,over,*,dup]
    27,[+,swap,+,*,2,*,rot,over,*,swap,dup]
    27,[+,swap,+,*,2,*,rot,tuck,swap,*,dup]
    29,[+,swap,+,*,2,*,rot,tuck,swap,*,swap,dup]

    % a b -- x
    swipl -s stackops -g 'juggle([a,b],a+b*a,X)'
    9,[+,*,tuck]
    11,[+,*,over,swap]
    ...

    % b a -- x
    3 ?- juggle([b,a],a*b+a*b,X).
    7,[*,dup,+]
    9,[*,dup,swap,+]
    11,[swap,swap,*,dup,+]
    ...
