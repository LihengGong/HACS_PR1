module org.crsx.hacs.samples.Pr1 {


/* LEXICAL ANALYSIS. */

space [ \t\n\r] | "//" .* 
                | "/" ⟨Aster⟩ ("/" | ⟨Other⟩ | ⟨Aster⟩+ ⟨Other⟩)* ⟨Aster⟩+ "/"; 
                // white space convention and comments

token INT     | ⟨Digit⟩+ ;                       // tokens
token FLOAT   | ⟨INT⟩ "." ⟨INT⟩ ;
token SPECIAL | ⟨Slash⟩ (⟨COctet⟩ | ⟨CHexdec⟩);
token STRING  | ⟨Quote⟩ ⟨Unquote⟩ ⟨Quote⟩;
token ID      | ⟨Lower⟩+ ('_'? ⟨INT⟩)? ;

token fragment Digit        | [0-9] ;
token fragment Lower        | [a-z] ;
token fragment Upper        | [A-Z];
token fragment Letter       | ⟨Lower⟩ | ⟨Upper⟩ | [\$_];
token fragment Quote        | \" ;
token fragment Unquote      | ⟨Letter⟩+ ⟨Digit⟩* | ⟨SPECIAL⟩;
token fragment Slash        | \\;
token fragment Controlchar  | [nt\\\"];

token fragment Aster        | [*];
token fragment Other        | [^/*]; /* all other chars other than slash and star */
token fragment Octet        | [0-7];
token fragment COctet       | ⟨Octet⟩
                            | ⟨Octet⟩⟨Octet⟩
                            | ⟨Octet⟩⟨Octet⟩⟨Octet⟩;

token fragment Hexdecimal   | [0-9a-fA-F];
token fragment CHexdec      | [xX] ⟨Hexdecimal⟩⟨Hexdecimal⟩;

/* SYNTAX ANALYSIS. */

sort Exp   | ⟦ ⟨Exp@1⟩ || ⟨Exp@2⟩ ⟧@1            // logical or
           | ⟦ ⟨Exp@2⟩ && ⟨Exp@3⟩ ⟧@2            // logical and
           | ⟦ ⟨Exp@3⟩ != ⟨Exp@4⟩ ⟧@3            // not equal
           | ⟦ ⟨Exp@3⟩ == ⟨Exp@4⟩ ⟧@3            // equal
           | ⟦ ⟨Exp@4⟩ >= ⟨Exp@5⟩ ⟧@4            // greater or equal
           | ⟦ ⟨Exp@4⟩ <= ⟨Exp@5⟩ ⟧@4            // less or equal
           | ⟦ ⟨Exp@4⟩ > ⟨Exp@5⟩ ⟧@4            // greater
           | ⟦ ⟨Exp@4⟩ < ⟨Exp@5⟩ ⟧@4            // less
           | ⟦ ⟨Exp@5⟩ + ⟨Exp@6⟩ ⟧@5            // addition
           | ⟦ ⟨Exp@5⟩ - ⟨Exp@6⟩ ⟧@5            // subtraction
           | ⟦ ⟨Exp@6⟩ * ⟨Exp@7⟩ ⟧@6            // multiplication
           | ⟦ ⟨Exp@6⟩ / ⟨Exp@7⟩ ⟧@6            // addition
           | ⟦ ⟨Exp@6⟩ % ⟨Exp@7⟩ ⟧@6            // addition
           | ⟦ +⟨Exp@8⟩⟧@7                     // positive
           | ⟦ -⟨Exp@8⟩⟧@7                      // negative
           | ⟦ *⟨Exp@8⟩⟧@7                     // pointer
           | ⟦ &⟨Exp@8⟩⟧@7                     // address
           | ⟦ ⟨INT⟩ ⟧@8                        // integer
           | ⟦ ⟨FLOAT⟩ ⟧@8                      // floating point number
           | ⟦ ⟨Name⟩ ⟧@8                       // assigned value
           | sugar ⟦ (⟨Exp#⟩) ⟧@8 → Exp#        // parenthesis
           ;

sort Name  | symbol ⟦ ⟨ID⟩ ⟧ ;                  // assigned symbols

main sort Stat  | ⟦ ⟨Name⟩ := ⟨Exp⟩ ; ⟨Stat⟩ ⟧
                | ⟦ { ⟨Stat⟩ } ⟨Stat⟩ ⟧
                | ⟦⟧
        ;


/* SEMANTIC SORTS & SCHEMES. */

sort Type | Int | Float ;

| scheme Unif(Type,Type) ;
Unif(Int, Int) → Int;
Unif(#t1, Float) → Float;
Unif(Float, #t2) → Float;


/* SEMANTIC ANALYSIS. */

attribute ↑t(Type);  // synthesized expression type
sort Exp | ↑t;

⟦ (⟨Exp#1 ↑t(#t1)⟩ + ⟨Exp#2 ↑t(#t2)⟩) ⟧ ↑t(Unif(#t1,#t2));
⟦ (⟨Exp#1 ↑t(#t1)⟩ * ⟨Exp#2 ↑t(#t2)⟩) ⟧ ↑t(Unif(#t1,#t2));
⟦ ⟨INT#⟩ ⟧ ↑t(Int);
⟦ ⟨FLOAT#⟩ ⟧ ↑t(Float);
// Variable ↑t populated by TA

attribute ↓e{Name:Type};  // inherited type environment

// TA: Type Analysis scheme.

sort Stat | scheme ⟦ TA ⟨Stat⟩ ⟧ ↓e ;

⟦ TA id := ⟨Exp#2⟩; ⟨Stat#3⟩ ⟧ → ⟦ TA2 id := TA ⟨Exp#2⟩; ⟨Stat#3⟩ ⟧;
{
  | scheme ⟦ TA2 ⟨Stat⟩ ⟧ ↓e;
  ⟦ TA2 id := ⟨Exp#2 ↑t(#t2)⟩; ⟨Stat#3⟩ ⟧ →
    ⟦ id := ⟨Exp#2⟩; ⟨Stat ⟦TA {⟨Stat#3⟩}⟧ ↓e{⟦id⟧:#t2}⟩ ⟧;
}
⟦ TA {⟨Stat#1⟩} ⟨Stat#2⟩ ⟧ → ⟦ {TA ⟨Stat#1⟩} TA ⟨Stat#2⟩ ⟧;

⟦ TA ⟧ → ⟦ ⟧;

sort Exp | scheme ⟦ TA ⟨Exp⟩ ⟧ ↓e ;

⟦ TA id ⟧ ↓e{⟦id⟧ : #t} → ⟦ id ⟧ ↑t(#t);

⟦ TA ⟨INT#⟩ ⟧ → ⟦ ⟨INT#⟩ ⟧;
⟦ TA ⟨FLOAT#⟩ ⟧ → ⟦ ⟨FLOAT#⟩ ⟧;
⟦ TA (⟨Exp#1⟩ + ⟨Exp#2⟩) ⟧ → ⟦ (TA ⟨Exp#1⟩) + (TA ⟨Exp#2⟩) ⟧;
⟦ TA (⟨Exp#1⟩ * ⟨Exp#2⟩) ⟧ → ⟦ (TA ⟨Exp#1⟩) * (TA ⟨Exp#2⟩) ⟧;


/* INTERMEDIATE CODE GENERATION. */

token T | T ('_' ⟨INT⟩)? ; // temporary

// Concrete syntax & abstract syntax sorts.

sort IProgr  | ⟦⟨IInstr⟩ ⟨IProgr⟩⟧ | ⟦⟧ ;

sort IInstr  | ⟦⟨Tmp⟩ = ⟨IArg⟩ + ⟨IArg⟩;¶⟧
         | ⟦⟨Tmp⟩ = ⟨IArg⟩ * ⟨IArg⟩;¶⟧
             | ⟦⟨Tmp⟩ = ⟨IArg⟩;¶⟧
             | ⟦⟨Name⟩ = ⟨Tmp⟩;¶⟧
         ;

sort IArg  | ⟦⟨Name⟩⟧
           | ⟦⟨FLOAT⟩⟧
           | ⟦⟨INT⟩⟧
       | ⟦⟨Tmp⟩⟧
       ;

sort Tmp | symbol ⟦ ⟨T⟩ ⟧ ;

// Translation scheme.

attribute ↓tmpType{Tmp:Type} ;

sort IProgr ;

| scheme ⟦ ICG ⟨Stat⟩ ⟧ ↓tmpType ;
⟦ ICG id := ⟨Exp#2 ↑t(#t2)⟩; ⟨Stat#3⟩ ⟧ → ⟦ { ⟨IProgr ⟦ICGExp T ⟨Exp#2⟩⟧ ↓tmpType{⟦T⟧:#t2}⟩ } id = T; ICG ⟨Stat#3⟩ ⟧ ;
⟦ ICG { ⟨Stat#1⟩ } ⟨Stat#2⟩ ⟧ → ⟦ { ICG ⟨Stat#1⟩ } ICG ⟨Stat#2⟩ ⟧ ;
⟦ ICG ⟧ → ⟦ ⟧ ;

| scheme ⟦ ICGExp ⟨Tmp⟩ ⟨Exp⟩ ⟧ ;

⟦ ICGExp T ⟨INT#1⟩ ⟧ → ⟦ T = ⟨INT#1⟩; ⟧ ;
⟦ ICGExp T ⟨FLOAT#1⟩ ⟧ → ⟦ T = ⟨FLOAT#1⟩; ⟧ ;
⟦ ICGExp T id ⟧ → ⟦ T = id; ⟧ ;

⟦ ICGExp T ⟨Exp#1⟩ + ⟨Exp#2⟩ ⟧
  → ⟦ {ICGExp T_1 ⟨Exp#1⟩} {ICGExp T_2 ⟨Exp#2⟩} T = T_1 + T_2; ⟧ ;

⟦ ICGExp T ⟨Exp#1⟩ * ⟨Exp#2⟩ ⟧
  → ⟦ {ICGExp T_1 ⟨Exp#1⟩} {ICGExp T_2 ⟨Exp#2⟩} T = T_1 * T_2; ⟧ ;

// Helper to flatten code sequence.
| scheme ⟦ {⟨IProgr⟩} ⟨IProgr⟩ ⟧;
⟦ {} ⟨IProgr#3⟩ ⟧ → #3 ;
⟦ {⟨IInstr#1⟩ ⟨IProgr#2⟩} ⟨IProgr#3⟩ ⟧ → ⟦ ⟨IInstr#1⟩ {⟨IProgr#2⟩} ⟨IProgr#3⟩ ⟧;


/* 6. CODE GENERATOR. */

// Concrete syntax & abstract syntax sorts.

sort AProgr  | ⟦ ⟨AInstr⟩ ⟨AProgr⟩ ⟧ | ⟦⟧ ;

sort AInstr  | ⟦ LDF ⟨Tmp⟩, ⟨AArg⟩¶⟧
             | ⟦ STF ⟨Name⟩, ⟨Tmp⟩¶⟧
             | ⟦ ADDF ⟨AArg⟩, ⟨AArg⟩, ⟨AArg⟩¶⟧
             | ⟦ MULF ⟨AArg⟩, ⟨AArg⟩, ⟨AArg⟩¶⟧
         ;

sort AArg | ⟦ #⟨FLOAT⟩ ⟧ | ⟦ #⟨INT⟩ ⟧ | ⟦ ⟨Name⟩ ⟧ | ⟦ ⟨Tmp⟩ ⟧ ;

// Schemes.

sort AProgr | scheme ⟦ CG ⟨IProgr⟩ ⟧ ;

⟦ CG ⟧ → ⟦⟧ ;

⟦ CG T = ⟨IArg#1⟩ + ⟨IArg#2⟩ ; ⟨IProgr#⟩ ⟧
  → ⟦ ADDF T, [⟨IArg#1⟩], [⟨IArg#2⟩] CG ⟨IProgr#⟩ ⟧ ;

⟦ CG T = ⟨IArg#1⟩ * ⟨IArg#2⟩ ; ⟨IProgr#⟩ ⟧
  → ⟦ MULF T, [⟨IArg#1⟩], [⟨IArg#2⟩] CG ⟨IProgr#⟩ ⟧ ;
  
⟦ CG T = ⟨IArg#1⟩ ; ⟨IProgr#⟩ ⟧
  → ⟦ LDF T, [⟨IArg#1⟩] CG ⟨IProgr#⟩ ⟧ ;

⟦ CG name = T ; ⟨IProgr#⟩ ⟧
  → ⟦ STF name, T CG ⟨IProgr#⟩ ⟧ ;

sort AArg ;

| scheme ⟦ [⟨IArg⟩] ⟧ ;
⟦ [T] ⟧ → ⟦ T ⟧ ;
⟦ [name] ⟧ → ⟦ name ⟧ ;
⟦ [⟨FLOAT#1⟩] ⟧ → ⟦ #⟨FLOAT#1⟩ ⟧ ;
⟦ [⟨INT#1⟩] ⟧ → ⟦ #⟨INT#1⟩ ⟧ ;


/* 7. MAIN. */

sort AProgr | scheme Compile(Stat);
Compile(#) → ⟦ CG ICG TA ⟨Stat#⟩ ⟧ ;


/* 8. OTHER STUFF. */

sort Exp | scheme Leftmost(Exp) ;
Leftmost(⟦⟨Exp#1⟩ + ⟨Exp#2⟩⟧)  →  Leftmost(Exp#1) ;
Leftmost(⟦⟨Exp#1⟩ * ⟨Exp#2⟩⟧)  →  Leftmost(Exp#1) ;
Leftmost(⟦⟨INT#⟩⟧)  →  ⟦⟨INT#⟩⟧ ;
Leftmost(⟦⟨FLOAT#⟩⟧)  →  ⟦⟨FLOAT#⟩⟧ ;
Leftmost(⟦id⟧)  →  ⟦id⟧ ;
}