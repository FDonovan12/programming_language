grammar Calculette;

@header {
  import java.io.FileOutputStream;
  import java.io.FileWriter;
  import java.io.File;
  import java.util.HashMap;
  import java.util.ArrayList;
}
@parser::members {

  HashMap<String, Integer> mapIndex = new HashMap<String, Integer>();
  int nombre = 0;
  private static final String[] _ops = { "+", "-","*","/" };
  private static final String[] _opcodes = { "ADD", "SUB","MUL","DIV"};


  private static final String[] _comps = { ">",">=","<","<=","==","!=","<>" };
  private static final String[] _compcodes = { "SUP", "SUPEQ","INF","INFEQ","EQUAL","NEQ","NEQ"};

  private int declaration = 0;

  private int label_ouvert = 0;
  HashMap<String, Integer> parametre = new HashMap<String, Integer>();
  HashMap<String, Integer> fonction = new HashMap<String, Integer>();
  HashMap<String, Integer> fonctionparams = new HashMap<String, Integer>();

  private String printWhile(String condition, String instruction){
    String retour = "";
    retour += "LABEL " + label_ouvert + "\n";
    retour += condition;
    retour += "JUMPF " + (label_ouvert+1) + "\n";
    retour += instruction;
    retour += "JUMP " + (label_ouvert) + "\n";
    retour += "LABEL " + (label_ouvert+1) + "\n";
    label_ouvert = label_ouvert + 2;
    return (retour);
  }

  private String printIf(String condition, String instructionThen, String instructionElse){
    String retour = "";
    retour += condition;
    retour += "JUMPF " + label_ouvert + "\n";
    retour += instructionThen;
    retour += "JUMP " + (label_ouvert+1) + "\n";
    retour += "LABEL " + (label_ouvert) + "\n";
    retour += instructionElse;
    retour += "LABEL " + (label_ouvert+1) + "\n";
    label_ouvert = label_ouvert + 2;
    return (retour);
  }

  private String printFor(String assignationDebut, String condition, String instruction, String assignationBoucle){
    String retour = "";
    retour += assignationDebut;
    retour += "LABEL " + label_ouvert + "\n";
    retour += condition;
    retour += "JUMPF " + (label_ouvert+1) + "\n";
    retour += instruction;
    retour += assignationBoucle;
    retour += "JUMP " + (label_ouvert) + "\n";
    retour += "LABEL " + (label_ouvert+1) + "\n";
    label_ouvert = label_ouvert + 2;
    return (retour);
  }

  private String printRepeat(String instruction, String condition){
    String retour = "";
    retour += "LABEL " + label_ouvert + "\n";
    retour += instruction;
    retour += condition;
    retour += "JUMPF " + (label_ouvert) + "\n";
    label_ouvert = label_ouvert + 1;
    return (retour);
  }

  private String printFonction(String instruction, String nom, int tailleParams){
    fonction.put(nom, label_ouvert);
    fonctionparams.put(nom, tailleParams);
    String retour = "";
    retour += "JUMP " + (label_ouvert+1) + "\n";
    retour += "LABEL " + label_ouvert + "\n";
    retour += instruction;
    retour += "LABEL " + (label_ouvert+1) + "\n";
    label_ouvert = label_ouvert + 2;
    return (retour);
  }

  private String printAppelFonction(String args, String nom, int tailleParams){
    if(fonction.get(nom) == null){
      throw new IllegalArgumentException("La fonction  : " + nom + " n'est pas connue");
    }
    if(tailleParams != fonctionparams.get(nom)){
      throw new IllegalArgumentException("Nombre d'argument pour  : " + nom + " est invalide");
    }
    String retour = "";
    retour += "PUSHI 0\n";
    retour += args;
    retour += "CALL " + (fonction.get(nom)) + "\n";
    for(int i = 0; i < tailleParams ; i++){
      retour += "POP \n";
    }
    return (retour);
  }

  private String printComparateur(String comp){
    for (int i = 0; i < _comps.length; i++){
      if (_comps[i].equals(comp)) return (_compcodes[i] + "\n");
    }
    return "compUnknown";
  }

  private String declaration(String a){
    if(mapIndex.get(a) == null){
      mapIndex.put(a,declaration);
      declaration++;
    }
    return "";
  }

  private String assignation(String a){
    if(mapIndex.get(a) == null){
      throw new IllegalArgumentException("Variable : " + a + " inconnue");
    }
    else{
      return "STOREG " + mapIndex.get(a) + "\n";
    }
  }

  private String addPush (int a ){
    String retour;
    retour = "PUSHI " + a + "\n";
    return retour;
  }

  private String opCode(String op) {
    for (int i = 0; i < _ops.length; i++)
    if (_ops[i].equals(op)) return _opcodes[i];
    System.err.println("Opérateur inconnu : '"+op+"'");
    return "opUnknown";
  }

  private String addId (String id){
    if(parametre.get(id) == null){
      if(mapIndex.get(id) == null){
        throw new IllegalArgumentException("Variable : " + id + " inconnue");
      }
      else{
        return "PUSHG " +  mapIndex.get(id)+ "\n";
      }
    }
    else{
      return "PUSHL -" +  (parametre.get(id)+3) + "\n";
    }
  }

    private void ecrireMvap (String code){
      String decl = "";
      code += "WRITE\n";
      for(int i = 0 ; i < declaration ; i++){
        decl += "PUSHI 0\n";
      }
      code += "HALT\n";
      code = decl + code;
        final String chemin = "./sources-MVaP-2.1/test.mvap";
    final File fichier =new File(chemin);
    try {
        // Creation du fichier
        fichier .createNewFile();
        // creation d'un writer (un écrivain)
        final FileWriter writer = new FileWriter(fichier);
        try {
            writer.write(code);
        } finally {
            writer.close();
        }
    } catch (Exception e) {
        System.out.println("Impossible de creer le fichier");
    }
  }
}

start returns [ String code ]
  : plusieurs {ecrireMvap ($plusieurs.code);}
  ;

plusieurs returns [ String code,]
  : {$code = "";}
  | instruction plusieurs {$code = $instruction.code + $plusieurs.code;}
  ;

instruction returns [ String code]
  : expr finInstruction {$code = $expr.code;}
  | assignation finInstruction {$code = $assignation.code + $finInstruction.code;}
  | decl finInstruction {$code = $decl.code + $finInstruction.code;}
  | boucleWhile {$code = $boucleWhile.code;}
  | branchementIf {$code = $branchementIf.code;}
  | boucleFor  {$code = $boucleFor.code;}
  | boucleRepeat {$code = $boucleRepeat.code;}
  | fonction {$code = $fonction.code;}
  | finInstruction {$code = $finInstruction.code;}
  ;

decl returns [ String code ]
  : TYPE IDENTIFIANT {$code = declaration($IDENTIFIANT.text);}
  ;

assignation returns [ String code ]
  : IDENTIFIANT '=' expr {$code = $expr.code + assignation($IDENTIFIANT.text);}
  | IDENTIFIANT '=' syntaxique {$code = $syntaxique.code + assignation($IDENTIFIANT.text);}
  ;

finInstruction returns [ String code ]
  : (NEWLINE | ';') {$code = "";}
  ;

expr returns[String code]
  : a=expr op=('*'|'/') b=expr {$code = $a.code + $b.code + opCode($op.text) + " " + "\n";}  # MulDiv
  | a=expr op=('+'|'-') b=expr {$code = $a.code + $b.code + opCode($op.text) + " " + "\n";} # AddSub
  | ('-') a =expr {$code = $a.code + "PUSHI -1\nMUL\n";} #Moins
  | ('+') a =expr {$code = $a.code;} #Plus
  | ENTIER {$code = addPush($ENTIER.int);}   # Int
  | '('expr')'  {$code = $expr.code;}          # Parens
  | IDENTIFIANT{$code = addId($IDENTIFIANT.text);} # Id
  | 'return' expr {$code = $expr.code + "STOREL -" + (parametre.size()+3) + "\nRETURN\n";} # Return
  | appelfonction {$code = $appelfonction.code;} # Appel
  ;

 boucleWhile returns[String code]
  : 'while' '('syntaxique')' instruction {$code = printWhile($syntaxique.code, $instruction.code);}
  | 'while' '('syntaxique')' bloc {$code = printWhile($syntaxique.code, $bloc.code);}
  ;

branchementIf returns[String code]
  : 'if' '('syntaxique')' a=instruction ('else' c=instruction) {$code = printIf($syntaxique.code, $a.code, $c.code);}
  | 'if' '('syntaxique')' a=instruction {$code = printIf($syntaxique.code, $a.code, "");}
  | 'if' '('syntaxique')' b=bloc ('else' d=bloc) {$code = printIf($syntaxique.code, $b.code, $d.code);}
  | 'if' '('syntaxique')' b=bloc {$code = printIf($syntaxique.code, $b.code, "");}
  ;

boucleFor returns[String code]
  : 'for' '(' a=assignation ';' syntaxique ';' b=assignation ')' instruction {$code = printFor($a.code, $syntaxique.code, $instruction.code, $b.code);}
  | 'for' '(' a=assignation ';' syntaxique ';' b=assignation ')' bloc {$code = printFor($a.code, $syntaxique.code, $bloc.code, $b.code);}
  ;

boucleRepeat returns[String code,]
  : 'repeat' instruction 'until' '('syntaxique')' {$code = printRepeat($instruction.code, $syntaxique.code);}
  | 'repeat' bloc 'until' '('syntaxique')' {$code = printRepeat($bloc.code, $syntaxique.code);}
  ;

bloc returns[String code,]
  : NEWLINE? '{' plusieurs '}' NEWLINE {$code = $plusieurs.code;}
  ;

fonction returns[String code]
@init{parametre.clear();}
  : TYPE IDENTIFIANT '(' params ')' bloc {$code = printFonction($bloc.code, $IDENTIFIANT.text, $params.size);}
  | TYPE IDENTIFIANT '(' ')' bloc {$code = printFonction($bloc.code, $IDENTIFIANT.text, 0);}
  ;

params returns[int size]
  : TYPE IDENTIFIANT {parametre.put($IDENTIFIANT.text, 0); $size = 1;}
  | TYPE IDENTIFIANT ',' a=params {parametre.put($IDENTIFIANT.text, $a.size); $size = $a.size + 1;}
  ;

appelfonction returns[String code]
  : IDENTIFIANT '(' args ')' {$code = printAppelFonction($args.code, $IDENTIFIANT.text, $args.size);}
  | IDENTIFIANT '(' ')' {$code = printAppelFonction("", $IDENTIFIANT.text, 0);}
  ;

args returns[String code, int size]
  : expr ',' args {$code = $expr.code + $args.code; $size = $args.size + 1;}
  | expr {$code = $expr.code; $size = 1;}
  ;

condition returns[String code]
  : 'true'  { $code = "PUSHI 1\n";}
  | 'false' { $code = "PUSHI 0\n";}
  | IDENTIFIANT {$code = "PUSHG " +  mapIndex.get($IDENTIFIANT.text)+ "\n";}
  | a=expr comp=COMPARATEUR b=expr { $code = $a.code + $b.code + printComparateur($comp.text);}
  ;

syntaxique returns[String code]
  : a=syntaxique 'or' b=syntaxique  { $code = $a.code + $b.code + "ADD\n"; }
  | a=syntaxique 'and' b=syntaxique { $code = $a.code + $b.code + "MUL\n"; }
  | 'not' syntaxique { $code = "PUSHI 0 \nEQUAL\n"; }
  | condition { $code = $condition.code; }
  ;
// lexer
NEWLINE : '\r'? '\n';

COMPARATEUR : '>'|'>='|'<'|'<='|'=='|'!='|'<>';

WS :   (' '|'\t')+ -> skip  ;

ENTIER : ('0'..'9')+  ;

TYPE : 'int' | 'bool'; //| 'float'

IDENTIFIANT : (('a'..'z' )|( 'A'..'Z'))+;

UNMATCH : . -> skip ;
