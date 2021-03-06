-- | Abstract syntax of the Clafer language.
module Language.Clafer.Front.Absclafer where
noSpan :: Span
noSpan = Span noPos noPos
noPos :: Pos
noPos = Pos 0 0

-- Haskell module generated by the BNF converter


newtype PosInteger = PosInteger ((Int,Int),String) deriving (Eq,Ord,Show)
newtype PosDouble = PosDouble ((Int,Int),String) deriving (Eq,Ord,Show)
newtype PosString = PosString ((Int,Int),String) deriving (Eq,Ord,Show)
newtype PosIdent = PosIdent ((Int,Int),String) deriving (Eq,Ord,Show)
data Module =
   Module [Declaration]
 | PosModule Span [Declaration]
  deriving (Eq,Ord,Show)

data Declaration =
   EnumDecl PosIdent [EnumId]
 | PosEnumDecl Span PosIdent [EnumId]
 | ElementDecl Element
 | PosElementDecl Span Element
  deriving (Eq,Ord,Show)

data Clafer =
   Clafer Abstract GCard PosIdent Super Card Init Elements
 | PosClafer Span Abstract GCard PosIdent Super Card Init Elements
  deriving (Eq,Ord,Show)

data Constraint =
   Constraint [Exp]
 | PosConstraint Span [Exp]
  deriving (Eq,Ord,Show)

data SoftConstraint =
   SoftConstraint [Exp]
 | PosSoftConstraint Span [Exp]
  deriving (Eq,Ord,Show)

data Goal =
   Goal [Exp]
 | PosGoal Span [Exp]
  deriving (Eq,Ord,Show)

data Abstract =
   AbstractEmpty
 | PosAbstractEmpty Span
 | Abstract
 | PosAbstract Span
  deriving (Eq,Ord,Show)

data Elements =
   ElementsEmpty
 | PosElementsEmpty Span
 | ElementsList [Element]
 | PosElementsList Span [Element]
  deriving (Eq,Ord,Show)

data Element =
   Subclafer Clafer
 | PosSubclafer Span Clafer
 | ClaferUse Name Card Elements
 | PosClaferUse Span Name Card Elements
 | Subconstraint Constraint
 | PosSubconstraint Span Constraint
 | Subgoal Goal
 | PosSubgoal Span Goal
 | Subsoftconstraint SoftConstraint
 | PosSubsoftconstraint Span SoftConstraint
  deriving (Eq,Ord,Show)

data Super =
   SuperEmpty
 | PosSuperEmpty Span
 | SuperSome SuperHow SetExp
 | PosSuperSome Span SuperHow SetExp
  deriving (Eq,Ord,Show)

data SuperHow =
   SuperColon
 | PosSuperColon Span
 | SuperArrow
 | PosSuperArrow Span
 | SuperMArrow
 | PosSuperMArrow Span
  deriving (Eq,Ord,Show)

data Init =
   InitEmpty
 | PosInitEmpty Span
 | InitSome InitHow Exp
 | PosInitSome Span InitHow Exp
  deriving (Eq,Ord,Show)

data InitHow =
   InitHow_1
 | PosInitHow_1 Span
 | InitHow_2
 | PosInitHow_2 Span
  deriving (Eq,Ord,Show)

data GCard =
   GCardEmpty
 | PosGCardEmpty Span
 | GCardXor
 | PosGCardXor Span
 | GCardOr
 | PosGCardOr Span
 | GCardMux
 | PosGCardMux Span
 | GCardOpt
 | PosGCardOpt Span
 | GCardInterval NCard
 | PosGCardInterval Span NCard
  deriving (Eq,Ord,Show)

data Card =
   CardEmpty
 | PosCardEmpty Span
 | CardLone
 | PosCardLone Span
 | CardSome
 | PosCardSome Span
 | CardAny
 | PosCardAny Span
 | CardNum PosInteger
 | PosCardNum Span PosInteger
 | CardInterval NCard
 | PosCardInterval Span NCard
  deriving (Eq,Ord,Show)

data NCard =
   NCard PosInteger ExInteger
 | PosNCard Span PosInteger ExInteger
  deriving (Eq,Ord,Show)

data ExInteger =
   ExIntegerAst
 | PosExIntegerAst Span
 | ExIntegerNum PosInteger
 | PosExIntegerNum Span PosInteger
  deriving (Eq,Ord,Show)

data Name =
   Path [ModId]
 | PosPath Span [ModId]
  deriving (Eq,Ord,Show)

data Exp =
   DeclAllDisj Decl Exp
 | PosDeclAllDisj Span Decl Exp
 | DeclAll Decl Exp
 | PosDeclAll Span Decl Exp
 | DeclQuantDisj Quant Decl Exp
 | PosDeclQuantDisj Span Quant Decl Exp
 | DeclQuant Quant Decl Exp
 | PosDeclQuant Span Quant Decl Exp
 | EGMax Exp
 | PosEGMax Span Exp
 | EGMin Exp
 | PosEGMin Span Exp
 | EIff Exp Exp
 | PosEIff Span Exp Exp
 | EImplies Exp Exp
 | PosEImplies Span Exp Exp
 | EOr Exp Exp
 | PosEOr Span Exp Exp
 | EXor Exp Exp
 | PosEXor Span Exp Exp
 | EAnd Exp Exp
 | PosEAnd Span Exp Exp
 | ENeg Exp
 | PosENeg Span Exp
 | ELt Exp Exp
 | PosELt Span Exp Exp
 | EGt Exp Exp
 | PosEGt Span Exp Exp
 | EEq Exp Exp
 | PosEEq Span Exp Exp
 | ELte Exp Exp
 | PosELte Span Exp Exp
 | EGte Exp Exp
 | PosEGte Span Exp Exp
 | ENeq Exp Exp
 | PosENeq Span Exp Exp
 | EIn Exp Exp
 | PosEIn Span Exp Exp
 | ENin Exp Exp
 | PosENin Span Exp Exp
 | QuantExp Quant Exp
 | PosQuantExp Span Quant Exp
 | EAdd Exp Exp
 | PosEAdd Span Exp Exp
 | ESub Exp Exp
 | PosESub Span Exp Exp
 | EMul Exp Exp
 | PosEMul Span Exp Exp
 | EDiv Exp Exp
 | PosEDiv Span Exp Exp
 | ESumSetExp Exp
 | PosESumSetExp Span Exp
 | ECSetExp Exp
 | PosECSetExp Span Exp
 | EMinExp Exp
 | PosEMinExp Span Exp
 | EImpliesElse Exp Exp Exp
 | PosEImpliesElse Span Exp Exp Exp
 | EInt PosInteger
 | PosEInt Span PosInteger
 | EDouble PosDouble
 | PosEDouble Span PosDouble
 | EStr PosString
 | PosEStr Span PosString
 | ESetExp SetExp
 | PosESetExp Span SetExp
  deriving (Eq,Ord,Show)

data SetExp =
   Union SetExp SetExp
 | PosUnion Span SetExp SetExp
 | UnionCom SetExp SetExp
 | PosUnionCom Span SetExp SetExp
 | Difference SetExp SetExp
 | PosDifference Span SetExp SetExp
 | Intersection SetExp SetExp
 | PosIntersection Span SetExp SetExp
 | Domain SetExp SetExp
 | PosDomain Span SetExp SetExp
 | Range SetExp SetExp
 | PosRange Span SetExp SetExp
 | Join SetExp SetExp
 | PosJoin Span SetExp SetExp
 | ClaferId Name
 | PosClaferId Span Name
  deriving (Eq,Ord,Show)

data Decl =
   Decl [LocId] SetExp
 | PosDecl Span [LocId] SetExp
  deriving (Eq,Ord,Show)

data Quant =
   QuantNo
 | PosQuantNo Span
 | QuantLone
 | PosQuantLone Span
 | QuantOne
 | PosQuantOne Span
 | QuantSome
 | PosQuantSome Span
  deriving (Eq,Ord,Show)

data EnumId =
   EnumIdIdent PosIdent
 | PosEnumIdIdent Span PosIdent
  deriving (Eq,Ord,Show)

data ModId =
   ModIdIdent PosIdent
 | PosModIdIdent Span PosIdent
  deriving (Eq,Ord,Show)

data LocId =
   LocIdIdent PosIdent
 | PosLocIdIdent Span PosIdent
  deriving (Eq,Ord,Show)

data Pos =
   Pos Integer Integer
 | PosPos Span Integer Integer
  deriving (Eq,Ord,Show)

data Span =
   Span Pos Pos
 | PosSpan Span Pos Pos
  deriving (Eq,Ord,Show)

