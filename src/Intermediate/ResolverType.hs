{-
 Copyright (C) 2012 Jimmy Liang, Kacper Bak <http://gsd.uwaterloo.ca>

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
-}
module Intermediate.ResolverType (resolveTModule) where

import Control.Monad.State
import Data.Function
import Data.Maybe
import Data.Map (Map)
import qualified Data.Map as Map
import Debug.Trace
import List (find)

import Common
import Intermediate.Intclafer

-- Internal structure for type checking.
-- A tuple for storing the symbol table, a clafer's uid, its type, and its parent uid.
-- Every clafer has a parent except the root.
data TCEnv = TCEnv {
    tcTable :: SymbolTable,
    tcThis :: String,
    tcType :: TC,
    tcParent :: Maybe String,
    tcReferenceTable :: Map String Bool -- Maps the Clafer uid to whether it is a reference or not.
} deriving Show

data TC =
    -- The type at the current node in the IR tree
    TC {typed::IType} |
    -- The current type is TClafer BUT it can be "ref"ed to the IType stored inside TCRef.
    -- This is important for models with quantifiers in the following form:
    --
    --   A : integer
    --     B *
    --   [some a : A | a.B + a = 5]
    --
    -- The bound expression must be of type "TC TInteger". The quantified expression can use "a" as
    -- either an integer value OR as a Clafer and access its children.
    -- The IType in TCVal must NOT be TClafer.
    TCVal {typed::IType}
    deriving Show

-- Internal structure for building the symbol table.
data STEnv = STEnv {
    stClafers :: [IClafer],
    -- The uid of the parent. Every clafer has a parent except the root.
    stParent :: Maybe String
} deriving Show

-- The symbol table maps a clafer's uid to its type and parent's uid.
-- Every clafer has a parent except the root.
type SymbolTable = Map String (IType, Maybe String)
type TypedPExp = (PExp, TC)
type TypedIExp = (IExp, TC)



-- Get the TCEnv of the parent
parentTCEnv :: TCEnv -> TCEnv
parentTCEnv t@(TCEnv table this itype (Just parent) _) = uidTCEnv t parent
parentTCEnv (TCEnv table this itype Nothing _)         = error "Root does not have a parent"
    
-- Get the TCEnv of the clafer matching the uid
uidTCEnv :: TCEnv -> String -> TCEnv
uidTCEnv (TCEnv table _ _ _ referenceTable) uid =
    case Map.lookup uid table of
    Just (TClafer, newParent) -> TCEnv table uid (TC TClafer) newParent referenceTable
    Just (newType, newParent) -> TCEnv table uid (TCVal newType) newParent referenceTable
    Nothing -> error $ "Unknown uid " ++ uid
    
    
identTCEnv :: TCEnv -> String -> TCEnv
identTCEnv env "this"   = env
identTCEnv env "parent" = parentTCEnv env
identTCEnv env "ref"    = env
identTCEnv env uid      = uidTCEnv env uid


isReference :: TCEnv -> Bool
isReference TCEnv{tcThis = this, tcReferenceTable = referenceTable} =
    Map.findWithDefault False this referenceTable


-- The only exported function. Type checks and resolves the types.
-- Done in 2 steps
--   1. Traverse every clafer and build a symbol table
--   2. Traverse every constraint and resolve the types and type check
resolveTModule :: (IModule, GEnv) -> IModule
resolveTModule (imodule, genv) =
    imodule {mDecls = resolveTElements tcEnv $ mDecls imodule}
    where
    symbolTable = symbolTableIElements (STEnv (sClafers genv) Nothing) (mDecls imodule)
    tcEnv = TCEnv symbolTable "root" (TC TClafer) Nothing referenceTable
    referenceTable = Map.fromList [(uid clafer, isReference clafer) | clafer <- sClafers genv]
    isReference = isOverlapping . super


{-
 -
 -  Symbol table building functions
 -
 -}
-- Build a symbol table from the elements
symbolTableIElements :: STEnv -> [IElement] -> SymbolTable
symbolTableIElements env elements = foldr (Map.union . symbolTableIElement env) Map.empty elements

symbolTableIElement :: STEnv -> IElement -> SymbolTable
symbolTableIElement env (IEClafer x) = symbolTableIClafer env x
-- Constraints do not add symbols to the symbol table
symbolTableIElement env (IEConstraint _ _) = Map.empty
-- Goald do not add symbols to the symbol table
symbolTableIElement env (IEGoal _ _) = Map.empty

symbolTableIClafer :: STEnv -> IClafer -> SymbolTable
symbolTableIClafer env c =
    let cuid = uid c :: String
        children = symbolTableIElements env{stParent = Just cuid} $ elements c :: SymbolTable
    in
    Map.insert cuid (itypeOfClafer env cuid, stParent env) children

itypeOfClafer :: STEnv -> String -> IType
itypeOfClafer env id = 
    let clafer = findClaferFromUid env id :: IClafer
        hierarchy = findHierarchy getSuper (stClafers env) clafer :: [IClafer]
    in
    -- Find the last IClafer (ie. highest in the hierarchy) and get super type
    typeOfISuper $ super $ last hierarchy

-- Find the clafer with the given uid
findClaferFromUid :: STEnv -> String -> IClafer
findClaferFromUid (STEnv clafers _) id = fromJust $ find (((==) id).uid) clafers
                                
-- Get the super's type (primitive => only one super so we only need to look at the first one)
-- The PExp must be a ClaferID
typeOfISuper :: ISuper -> IType
typeOfISuper (ISuper _ ((PExp _ _ _ (IClaferId _ sident _)):_)) = case sident of
                                                                    "clafer" -> TClafer
                                                                    "int" -> TInteger
                                                                    "integer" -> TInteger
                                                                    "string" -> TString
                                                                    x -> error $ sident ++ " not a native super type"



{-
 -
 -  Type checking and type resolving functions
 -
 -}
-- Type check the elements
resolveTElements :: TCEnv -> [IElement] -> [IElement]
resolveTElements env es = map (resolveTElement env) es

resolveTElement :: TCEnv -> IElement -> IElement
resolveTElement env (IEClafer clafer) = IEClafer $ resolveTClafer env clafer
resolveTElement env (IEConstraint isHard pexp) = IEConstraint isHard resolvedPExp where (_, (resolvedPExp, _)) = resolveTPExp env pexp    
resolveTElement env (IEGoal isMaximize pexp) = IEGoal isMaximize resolvedPExp where (_, (resolvedPExp, _)) = resolveTPExp env pexp    
                                                                                        
resolveTClafer :: TCEnv -> IClafer -> IClafer
resolveTClafer env clafer = 
    clafer{
        elements = resolveTElements cenv $ elements clafer,
        super = typeTheSuper $ super clafer}
    where cenv = uidTCEnv env (uid clafer)

-- Sets the type in all the supers to IClafer
typeTheSuper :: ISuper -> ISuper
typeTheSuper (ISuper isOverlapping supers) = ISuper isOverlapping $ map typeThePExp supers
typeThePExp :: PExp -> PExp
typeThePExp x = x{iType=Just TClafer}


resolveTPExpPreferValue :: TCEnv -> PExp -> (TCEnv, TypedPExp)
resolveTPExpPreferValue env (PExp _ pid pos x) =
    (newEnv, (pexp', expType))
    where
    (newEnv, (exp, expType)) = resolveTExpPreferValue env x
    pexp = PExp (Just $ tcToType expType) pid pos exp
    -- Sometimes need to dereference an access. For example:
    --   Leader -> Person
    --   abstract Person
    --   A : Person
    --   B : Person
    --   [Leader = A]
    -- Need to add a "ref" node into the IR on the access to "Leader"
    pexp'
        | isClaferId exp && isReference newEnv =
            newPExp (Just TClafer) $ IFunExp "." [pexp, newPExp (Just $ typed expType) $ IClaferId "" "ref" False]
        | otherwise = pexp
    isClaferId IClaferId{} = True
    isClaferId _           = False
    newPExp t = PExp t "" pos

    
resolveTPExp :: TCEnv -> PExp -> (TCEnv, TypedPExp)
resolveTPExp env (PExp _ pid pos x) =
    let (newEnv, (exp, typed)) = resolveTExp env x in
    (newEnv, (PExp (Just $ tcToType typed) pid pos exp, typed))



{-
    There are two ways to retrieve the type of an IExp:
        resolveTExpPreferValue or resolveTExp
    
    Some functions prefer/require working with values, ie. int, string, etc. In this case,
    call resolveTExpPreferValue and a value type will return if the expression allows.
    Functions that prefer/require working with IClafer calls resolveTExp.
    
    Returns a tuple of the type checked expression and the type.
-}
resolveTExpPreferValue:: TCEnv -> IExp -> (TCEnv, TypedIExp)
-- Clafer reference
-- Return the value type of the reference from the symbol table (possibly IClafer)
resolveTExpPreferValue env e@(IClaferId _ sident _) =
    (env', (e, t))
    where
    env' = identTCEnv env sident
    -- If it's TCVal, then get the actual value type
    t = TC $ typed $ tcType env'
-- Join function
{- 
 - Join function is a special case.
 - The expression a.b can produce a value if b can produce a value.
 - Join function is the only function that passes along the TCEnv of its children
 - This is needed to support parent and this relation.
 -
 - for example: ((parent.parent).this)
 - In the first join, the left child (parent) will create a TCEnv for the parent of the current TCEnv.
 - The right child (parent) will create a TCEnv for the parent of that parent (hence grandparent of the orignal TCEnv).
 - The grandparent TCEnv will be given to the outer join to pass to its right child (this).
 - this refers to the current TCEnv so the example expression is evaluated to the grandparent of the current TCEnv.
 -}
resolveTExpPreferValue env (IFunExp "." [exp1, exp2]) =
    let (env1, a1) = resolveTPExpLeftJoin env exp1
        (env2, a2) = resolveTPExpPreferValue env1 exp2
    in
    (env2, typeCheckFunction (typeOf a2) "." [E TClafer, EAny] [a1, a2])
-- Otherwise, the IExp has no value expression so return its standard expression
resolveTExpPreferValue env x = resolveTExp env x



resolveTExp:: TCEnv -> IExp -> (TCEnv, TypedIExp)
resolveTExp env e@(IClaferId _ sident _) =
    (env', (e, t))
    where
    env' = identTCEnv env sident
    t = tcType env'
    
resolveTExp env (IFunExp "." [exp1, exp2]) =
    let (env1, a1) = resolveTPExp env exp1
        (env2, a2) = resolveTPExp env1 exp2
    in
    (env2, typeCheckFunction (typeOf a2) "." [E TClafer, EAny] [a1, a2])
resolveTExp env e@(IInt _) =          (env, (e, TC TInteger))
resolveTExp env e@(IDouble _) =       (env, (e, TC TReal))
resolveTExp env e@(IStr _) =          (env, (e, TC TString))
resolveTExp env e@(IDeclPExp quant decls bpexp) = (env, (IDeclPExp quant decls' bpexp', TC TBoolean))
    where
    (env', decls') = resolveTDecls env decls
    (_, (bpexp', bpexpType')) = resolveTPExp env' bpexp
    
    resolveTDecls env [] = (env, [])
    resolveTDecls env (d : ds) =
        (env'', d' : ds')
        where
        (env', d') = resolveTDecl env d
        (env'', ds') = resolveTDecls env' ds
    resolveTDecl env (IDecl isDisj decls body) =
        (env', IDecl isDisj decls body')
        where
        (_, (body', bodyType')) = resolveTPExp env body
        -- Retrieve the actual type and bind it to the declaration
        env' = env{tcTable = foldr (flip Map.insert $ (typed bodyType', Nothing)) (tcTable env) decls}


-- Unary functions
-- Rafael Olaechea 02/April/2012: Added function resolveTPExpPreferValue to be used when using goals or negative.
resolveTExp env (IFunExp op [exp]) = (env, result)
    where
    result
        | op == iNot  = typeCheckFunction (TC TBoolean) op [E TBoolean] [a1]
        | op == iCSet = typeCheckFunction (TC TInteger) op [E TClafer] [a1]
        -- We return the typeOf a1 because if a1 is real then return real (likewise for integer)
        | op == iMin  = typeCheckFunction t1PV op allNumeric         [a1PreferValue]
        | op == iGMax = typeCheckFunction t1PV op allNumeric         [a1PreferValue]
        | op == iGMin = typeCheckFunction t1PV op allNumeric         [a1PreferValue]
        | otherwise   = error $ "Unknown unary function '" ++ op ++ "'"
    (_, a1) = resolveTPExp env exp
    (_, a1PreferValue) = resolveTPExpPreferValue env exp
    t1PV = typeOf a1PreferValue

-- Binary functions
resolveTExp env (IFunExp op [exp1, exp2]) = (env, result)
    where
    result
        | op `elem` logBinOps = 
            typeCheckFunction (TC TBoolean) op (exact [TBoolean, TBoolean])  [a1, a2]
        | op `elem` [iLt, iGt, iLte, iGte] =
            typeCheckFunction (TC TBoolean) op allNumeric  [a1PreferValue, a2PreferValue]
        | op `elem` [iEq, iNeq] =
            if isExact (tcToType t1PV) TString then -- String equality
                typeCheckFunction (TC TBoolean) op [E TString, E TString] [a1PreferValue, a2PreferValue]
            else if isNumeric $ tcToType t1PV then -- Numeric equality
                typeCheckFunction (TC TBoolean) op allNumeric [a1PreferValue, a2PreferValue]
            else -- Set equality
                typeCheckFunction (TC TBoolean) op [E TClafer, E TClafer] [a1PreferValue, a2PreferValue]
        | op `elem` relSetBinOps = 
            -- Expect both arguments to be the same type as the first argument
            typeCheckFunction (TC TBoolean) op [E $ tcToType t1PV, E $ tcToType t1PV]  [a1PreferValue, a2PreferValue]
        | op `elem` [iUnion, iDifference, iIntersection] =
            -- Expect both arguments to be the same type as the first argument
            typeCheckFunction t1PV op [E $ tcToType t1PV, E $ tcToType t1PV]  [a1PreferValue, a2PreferValue]
        | op `elem` [iUnion, iDifference, iIntersection] =
            typeCheckFunction (TC TClafer) op [E TClafer, E TClafer]  [a1, a2]
        | op `elem` [iDomain, iRange] =
            typeCheckFunction (TC TClafer) op [E TClafer, EAny]  [a1, a2PreferValue]
        | op `elem` [iSub, iMul, iDiv] =
            typeCheckFunction (coerceIfNeeded t1PV t2PV) op allNumeric [a1PreferValue, a2PreferValue]
        | op == iPlus =
            if isExact (tcToType t1PV) TString then -- String addition
                typeCheckFunction (TC TString) op [E TString, E TString] [a1PreferValue, a2PreferValue]
            else -- Numeric addition or fail
                typeCheckFunction (coerceIfNeeded t1PV t2PV) op allNumeric [a1PreferValue, a2PreferValue]
    (_, a1) = resolveTPExp env exp1
    (_, a2) = resolveTPExp env exp2
    (_, a1PreferValue) = resolveTPExpPreferValue env exp1
    (_, a2PreferValue) = resolveTPExpPreferValue env exp2
    t1 = typeOf a1
    t2 = typeOf a2
    t1PV = typeOf a1PreferValue
    t2PV = typeOf a2PreferValue

--Ternary functions
resolveTExp env (IFunExp "=>else" [exp1, exp2, exp3]) = (env, result)
    where
    result
        | isExact (tcToType t2) TString = -- String expression
            typeCheckFunction (TC TBoolean) "=>else" [E TBoolean, E TString, E TString] [a1, a2, a3]
        | isNumeric $ tcToType t2 = -- Numeric expression
            typeCheckFunction (TC TBoolean) "=>else" [E TBoolean, ENumeric, ENumeric] [a1, a2, a3]
        | otherwise = -- Clafer expression
            typeCheckFunction (TC TBoolean) "=>else" [E TBoolean, E TClafer, E TClafer] [a1, a2, a3]
    (_, a1) = resolveTPExpPreferValue env exp1
    (_, a2) = resolveTPExpPreferValue env exp2
    (_, a3) = resolveTPExpPreferValue env exp3
    
    t1 = typeOf a1
    t2 = typeOf a2
    t3 = typeOf a3


resolveTPExpLeftJoin :: TCEnv -> PExp -> (TCEnv, TypedPExp)
resolveTPExpLeftJoin env (PExp _ pid pos e@(IClaferId _ "this" _)) =
    (env, (PExp (Just TClafer) pid pos e, TC TClafer))
resolveTPExpLeftJoin env pexp = resolveTPExp env pexp


--resolveTDecl :: IDecl ->  IDecl
--resolveTDecl x = liftM x{body = resolveTPExp $ body x}

typeOf = snd

coerceIfNeeded:: TC -> TC -> TC
coerceIfNeeded (TC TInteger) (TC TReal) = TC TReal -- Coerce to real
coerceIfNeeded (TC TReal) (TC TInteger) = TC TReal -- Coerce to real
coerceIfNeeded x _ = x                -- No coercing

-- Expects that each argument is numeric
allNumeric :: [TExpect]
allNumeric = repeat ENumeric

-- Expects that each argument is of the exact type
exact :: [IType] -> [TExpect]
exact = map E

-- Type checks each argument.
--   Each argument must match exactly with the expect type (aka E), is numeric (ENumeric), is Clafer or
--   don't care (EAny).
--   E is an EXACT match, ie. TInteger does not match with TReal. Use ENumeric where necessary.
--   Returns a tuple of a IFunExp and its type if type checking passes.
typeCheckFunction :: TC -> String -> [TExpect] -> [TypedPExp] -> TypedIExp
typeCheckFunction returnType op expected inferredChildren =
    let inferred = map (tcToType . typeOf) inferredChildren in
        if all (uncurry checkExpect) (zip expected inferred) then 
            (IFunExp op $ map fst inferredChildren, returnType)
        else error ("function " ++ op ++ " expected arguments of type " ++ show (take (length inferred) expected)
            ++ ", received " ++ show inferred)

-- Convenience function, returns true iff the type is a numerical type.
isNumeric :: IType -> Bool
isNumeric itype = checkExpect ENumeric itype

-- Convenience function, returns true iff the type is exact type.
isExact :: IType -> IType -> Bool
isExact a b = checkExpect (E a) b

-- Return true iff IType matches the expected type.
checkExpect :: TExpect -> IType -> Bool
-- Check exact match.
checkExpect (E exact) itype = exact == itype
-- Check is numeric.
checkExpect ENumeric TInteger = True
checkExpect ENumeric TReal    = True
checkExpect ENumeric _        = False
-- Check allows anything
checkExpect EAny _ = True


tcToType (TC t) = t
tcToType (TCVal t) = TClafer -- It's type is TClafer, it can be "ref"ed to t.


data TExpect =
    E IType |        -- The exact type
    ENumeric | -- TInteger or TReal
    EAny       -- No expectations
instance Show TExpect where
    show (E itype) = show itype
    show ENumeric = (show TInteger) ++ "/" ++ (show TReal)
    show EAny = "*"
