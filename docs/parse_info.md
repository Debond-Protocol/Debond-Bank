├─ type: SourceUnit
└─ children
   ├─ 0
   │  ├─ type: PragmaDirective
   │  ├─ name: solidity
   │  └─ value: ^0.8.0
   ├─ 1
   │  ├─ type: ImportDirective
   │  ├─ path: apm-contracts/interfaces/IAPM.sol
   │  ├─ unitAlias
   │  └─ symbolAliases
   ├─ 2
   │  ├─ type: ImportDirective
   │  ├─ path: @openzeppelin/contracts/token/ERC20/IERC20.sol
   │  ├─ unitAlias
   │  └─ symbolAliases
   └─ 3
      ├─ type: ContractDefinition
      ├─ name: APMRouter
      ├─ baseContracts
      ├─ subNodes
      │  ├─ 0
      │  │  ├─ type: StateVariableDeclaration
      │  │  ├─ variables
      │  │  │  └─ 0
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: UserDefinedTypeName
      │  │  │     │  └─ namePath: IAPM
      │  │  │     ├─ name: apm
      │  │  │     ├─ expression
      │  │  │     ├─ visibility: default
      │  │  │     ├─ isStateVar: true
      │  │  │     ├─ isDeclaredConst: false
      │  │  │     ├─ isIndexed: false
      │  │  │     ├─ isImmutable: false
      │  │  │     └─ override
      │  │  └─ initialValue
      │  ├─ 1
      │  │  ├─ type: FunctionDefinition
      │  │  ├─ name
      │  │  ├─ parameters
      │  │  │  └─ 0
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: ElementaryTypeName
      │  │  │     │  └─ name: address
      │  │  │     ├─ name: apmAddress
      │  │  │     ├─ storageLocation
      │  │  │     ├─ isStateVar: false
      │  │  │     └─ isIndexed: false
      │  │  ├─ returnParameters
      │  │  ├─ body
      │  │  │  ├─ type: Block
      │  │  │  └─ statements
      │  │  │     └─ 0
      │  │  │        ├─ type: ExpressionStatement
      │  │  │        └─ expression
      │  │  │           ├─ type: BinaryOperation
      │  │  │           ├─ operator: =
      │  │  │           ├─ left
      │  │  │           │  ├─ type: Identifier
      │  │  │           │  └─ name: apm
      │  │  │           └─ right
      │  │  │              ├─ type: FunctionCall
      │  │  │              ├─ expression
      │  │  │              │  ├─ type: Identifier
      │  │  │              │  └─ name: IAPM
      │  │  │              ├─ arguments
      │  │  │              │  └─ 0
      │  │  │              │     ├─ type: Identifier
      │  │  │              │     └─ name: apmAddress
      │  │  │              └─ names
      │  │  ├─ visibility: default
      │  │  ├─ modifiers
      │  │  ├─ override
      │  │  ├─ isConstructor: true
      │  │  ├─ isReceiveEther: false
      │  │  ├─ isFallback: false
      │  │  ├─ isVirtual: false
      │  │  └─ stateMutability
      │  ├─ 2
      │  │  ├─ type: FunctionDefinition
      │  │  ├─ name: updateWhenAddLiquidity
      │  │  ├─ parameters
      │  │  │  ├─ 0
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: uint
      │  │  │  │  ├─ name: _amountA
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  ├─ 1
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: uint
      │  │  │  │  ├─ name: _amountB
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  ├─ 2
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: address
      │  │  │  │  ├─ name: _tokenA
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  └─ 3
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: ElementaryTypeName
      │  │  │     │  └─ name: address
      │  │  │     ├─ name: _tokenB
      │  │  │     ├─ storageLocation
      │  │  │     ├─ isStateVar: false
      │  │  │     └─ isIndexed: false
      │  │  ├─ returnParameters
      │  │  ├─ body
      │  │  │  ├─ type: Block
      │  │  │  └─ statements
      │  │  │     └─ 0
      │  │  │        ├─ type: ExpressionStatement
      │  │  │        └─ expression
      │  │  │           ├─ type: FunctionCall
      │  │  │           ├─ expression
      │  │  │           │  ├─ type: MemberAccess
      │  │  │           │  ├─ expression
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: apm
      │  │  │           │  └─ memberName: updateWhenAddLiquidity
      │  │  │           ├─ arguments
      │  │  │           │  ├─ 0
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: _amountA
      │  │  │           │  ├─ 1
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: _amountB
      │  │  │           │  ├─ 2
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: _tokenA
      │  │  │           │  └─ 3
      │  │  │           │     ├─ type: Identifier
      │  │  │           │     └─ name: _tokenB
      │  │  │           └─ names
      │  │  ├─ visibility: internal
      │  │  ├─ modifiers
      │  │  ├─ override
      │  │  ├─ isConstructor: false
      │  │  ├─ isReceiveEther: false
      │  │  ├─ isFallback: false
      │  │  ├─ isVirtual: false
      │  │  └─ stateMutability
      │  ├─ 3
      │  │  ├─ type: FunctionDefinition
      │  │  ├─ name: swapExactTokensForTokens
      │  │  ├─ parameters
      │  │  │  ├─ 0
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: uint
      │  │  │  │  ├─ name: amountIn
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  ├─ 1
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: uint
      │  │  │  │  ├─ name: amountOutMin
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  ├─ 2
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ArrayTypeName
      │  │  │  │  │  ├─ baseTypeName
      │  │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  │  └─ name: address
      │  │  │  │  │  └─ length
      │  │  │  │  ├─ name: path
      │  │  │  │  ├─ storageLocation: calldata
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  └─ 3
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: ElementaryTypeName
      │  │  │     │  └─ name: address
      │  │  │     ├─ name: to
      │  │  │     ├─ storageLocation
      │  │  │     ├─ isStateVar: false
      │  │  │     └─ isIndexed: false
      │  │  ├─ returnParameters
      │  │  ├─ body
      │  │  │  ├─ type: Block
      │  │  │  └─ statements
      │  │  │     ├─ 0
      │  │  │     │  ├─ type: VariableDeclarationStatement
      │  │  │     │  ├─ variables
      │  │  │     │  │  └─ 0
      │  │  │     │  │     ├─ type: VariableDeclaration
      │  │  │     │  │     ├─ typeName
      │  │  │     │  │     │  ├─ type: ArrayTypeName
      │  │  │     │  │     │  ├─ baseTypeName
      │  │  │     │  │     │  │  ├─ type: ElementaryTypeName
      │  │  │     │  │     │  │  └─ name: uint
      │  │  │     │  │     │  └─ length
      │  │  │     │  │     ├─ name: amounts
      │  │  │     │  │     ├─ storageLocation: memory
      │  │  │     │  │     ├─ isStateVar: false
      │  │  │     │  │     └─ isIndexed: false
      │  │  │     │  └─ initialValue
      │  │  │     │     ├─ type: FunctionCall
      │  │  │     │     ├─ expression
      │  │  │     │     │  ├─ type: MemberAccess
      │  │  │     │     │  ├─ expression
      │  │  │     │     │  │  ├─ type: Identifier
      │  │  │     │     │  │  └─ name: apm
      │  │  │     │     │  └─ memberName: getAmountsOut
      │  │  │     │     ├─ arguments
      │  │  │     │     │  ├─ 0
      │  │  │     │     │  │  ├─ type: Identifier
      │  │  │     │     │  │  └─ name: amountIn
      │  │  │     │     │  └─ 1
      │  │  │     │     │     ├─ type: Identifier
      │  │  │     │     │     └─ name: path
      │  │  │     │     └─ names
      │  │  │     ├─ 1
      │  │  │     │  ├─ type: ExpressionStatement
      │  │  │     │  └─ expression
      │  │  │     │     ├─ type: FunctionCall
      │  │  │     │     ├─ expression
      │  │  │     │     │  ├─ type: Identifier
      │  │  │     │     │  └─ name: require
      │  │  │     │     ├─ arguments
      │  │  │     │     │  ├─ 0
      │  │  │     │     │  │  ├─ type: BinaryOperation
      │  │  │     │     │  │  ├─ operator: >=
      │  │  │     │     │  │  ├─ left
      │  │  │     │     │  │  │  ├─ type: IndexAccess
      │  │  │     │     │  │  │  ├─ base
      │  │  │     │     │  │  │  │  ├─ type: Identifier
      │  │  │     │     │  │  │  │  └─ name: amounts
      │  │  │     │     │  │  │  └─ index
      │  │  │     │     │  │  │     ├─ type: BinaryOperation
      │  │  │     │     │  │  │     ├─ operator: -
      │  │  │     │     │  │  │     ├─ left
      │  │  │     │     │  │  │     │  ├─ type: MemberAccess
      │  │  │     │     │  │  │     │  ├─ expression
      │  │  │     │     │  │  │     │  │  ├─ type: Identifier
      │  │  │     │     │  │  │     │  │  └─ name: amounts
      │  │  │     │     │  │  │     │  └─ memberName: length
      │  │  │     │     │  │  │     └─ right
      │  │  │     │     │  │  │        ├─ type: NumberLiteral
      │  │  │     │     │  │  │        ├─ number: 1
      │  │  │     │     │  │  │        └─ subdenomination
      │  │  │     │     │  │  └─ right
      │  │  │     │     │  │     ├─ type: Identifier
      │  │  │     │     │  │     └─ name: amountOutMin
      │  │  │     │     │  └─ 1
      │  │  │     │     │     ├─ type: StringLiteral
      │  │  │     │     │     ├─ value: UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT
      │  │  │     │     │     └─ parts
      │  │  │     │     │        └─ 0: UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT
      │  │  │     │     └─ names
      │  │  │     ├─ 2
      │  │  │     │  ├─ type: ExpressionStatement
      │  │  │     │  └─ expression
      │  │  │     │     ├─ type: FunctionCall
      │  │  │     │     ├─ expression
      │  │  │     │     │  ├─ type: MemberAccess
      │  │  │     │     │  ├─ expression
      │  │  │     │     │  │  ├─ type: FunctionCall
      │  │  │     │     │  │  ├─ expression
      │  │  │     │     │  │  │  ├─ type: Identifier
      │  │  │     │     │  │  │  └─ name: IERC20
      │  │  │     │     │  │  ├─ arguments
      │  │  │     │     │  │  │  └─ 0
      │  │  │     │     │  │  │     ├─ type: IndexAccess
      │  │  │     │     │  │  │     ├─ base
      │  │  │     │     │  │  │     │  ├─ type: Identifier
      │  │  │     │     │  │  │     │  └─ name: path
      │  │  │     │     │  │  │     └─ index
      │  │  │     │     │  │  │        ├─ type: NumberLiteral
      │  │  │     │     │  │  │        ├─ number: 0
      │  │  │     │     │  │  │        └─ subdenomination
      │  │  │     │     │  │  └─ names
      │  │  │     │     │  └─ memberName: transferFrom
      │  │  │     │     ├─ arguments
      │  │  │     │     │  ├─ 0
      │  │  │     │     │  │  ├─ type: MemberAccess
      │  │  │     │     │  │  ├─ expression
      │  │  │     │     │  │  │  ├─ type: Identifier
      │  │  │     │     │  │  │  └─ name: msg
      │  │  │     │     │  │  └─ memberName: sender
      │  │  │     │     │  ├─ 1
      │  │  │     │     │  │  ├─ type: FunctionCall
      │  │  │     │     │  │  ├─ expression
      │  │  │     │     │  │  │  ├─ type: TypeNameExpression
      │  │  │     │     │  │  │  └─ typeName
      │  │  │     │     │  │  │     ├─ type: ElementaryTypeName
      │  │  │     │     │  │  │     └─ name: address
      │  │  │     │     │  │  ├─ arguments
      │  │  │     │     │  │  │  └─ 0
      │  │  │     │     │  │  │     ├─ type: Identifier
      │  │  │     │     │  │  │     └─ name: apm
      │  │  │     │     │  │  └─ names
      │  │  │     │     │  └─ 2
      │  │  │     │     │     ├─ type: IndexAccess
      │  │  │     │     │     ├─ base
      │  │  │     │     │     │  ├─ type: Identifier
      │  │  │     │     │     │  └─ name: amounts
      │  │  │     │     │     └─ index
      │  │  │     │     │        ├─ type: NumberLiteral
      │  │  │     │     │        ├─ number: 0
      │  │  │     │     │        └─ subdenomination
      │  │  │     │     └─ names
      │  │  │     └─ 3
      │  │  │        ├─ type: ExpressionStatement
      │  │  │        └─ expression
      │  │  │           ├─ type: FunctionCall
      │  │  │           ├─ expression
      │  │  │           │  ├─ type: Identifier
      │  │  │           │  └─ name: _swap
      │  │  │           ├─ arguments
      │  │  │           │  ├─ 0
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: amounts
      │  │  │           │  ├─ 1
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: path
      │  │  │           │  └─ 2
      │  │  │           │     ├─ type: Identifier
      │  │  │           │     └─ name: to
      │  │  │           └─ names
      │  │  ├─ visibility: external
      │  │  ├─ modifiers
      │  │  ├─ override
      │  │  ├─ isConstructor: false
      │  │  ├─ isReceiveEther: false
      │  │  ├─ isFallback: false
      │  │  ├─ isVirtual: false
      │  │  └─ stateMutability
      │  ├─ 4
      │  │  ├─ type: FunctionDefinition
      │  │  ├─ name: removeLiquidity
      │  │  ├─ parameters
      │  │  │  ├─ 0
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: address
      │  │  │  │  ├─ name: _to
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  ├─ 1
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: address
      │  │  │  │  ├─ name: tokenAddress
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  └─ 2
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: ElementaryTypeName
      │  │  │     │  └─ name: uint
      │  │  │     ├─ name: amount
      │  │  │     ├─ storageLocation
      │  │  │     ├─ isStateVar: false
      │  │  │     └─ isIndexed: false
      │  │  ├─ returnParameters
      │  │  ├─ body
      │  │  │  ├─ type: Block
      │  │  │  └─ statements
      │  │  │     └─ 0
      │  │  │        ├─ type: ExpressionStatement
      │  │  │        └─ expression
      │  │  │           ├─ type: FunctionCall
      │  │  │           ├─ expression
      │  │  │           │  ├─ type: MemberAccess
      │  │  │           │  ├─ expression
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: apm
      │  │  │           │  └─ memberName: removeLiquidity
      │  │  │           ├─ arguments
      │  │  │           │  ├─ 0
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: _to
      │  │  │           │  ├─ 1
      │  │  │           │  │  ├─ type: Identifier
      │  │  │           │  │  └─ name: tokenAddress
      │  │  │           │  └─ 2
      │  │  │           │     ├─ type: Identifier
      │  │  │           │     └─ name: amount
      │  │  │           └─ names
      │  │  ├─ visibility: internal
      │  │  ├─ modifiers
      │  │  ├─ override
      │  │  ├─ isConstructor: false
      │  │  ├─ isReceiveEther: false
      │  │  ├─ isFallback: false
      │  │  ├─ isVirtual: false
      │  │  └─ stateMutability
      │  ├─ 5
      │  │  ├─ type: FunctionDefinition
      │  │  ├─ name: getReserves
      │  │  ├─ parameters
      │  │  │  ├─ 0
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: address
      │  │  │  │  ├─ name: tokenA
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  └─ 1
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: ElementaryTypeName
      │  │  │     │  └─ name: address
      │  │  │     ├─ name: tokenB
      │  │  │     ├─ storageLocation
      │  │  │     ├─ isStateVar: false
      │  │  │     └─ isIndexed: false
      │  │  ├─ returnParameters
      │  │  │  ├─ 0
      │  │  │  │  ├─ type: VariableDeclaration
      │  │  │  │  ├─ typeName
      │  │  │  │  │  ├─ type: ElementaryTypeName
      │  │  │  │  │  └─ name: uint
      │  │  │  │  ├─ name: _reserveA
      │  │  │  │  ├─ storageLocation
      │  │  │  │  ├─ isStateVar: false
      │  │  │  │  └─ isIndexed: false
      │  │  │  └─ 1
      │  │  │     ├─ type: VariableDeclaration
      │  │  │     ├─ typeName
      │  │  │     │  ├─ type: ElementaryTypeName
      │  │  │     │  └─ name: uint
      │  │  │     ├─ name: _reserveB
      │  │  │     ├─ storageLocation
      │  │  │     ├─ isStateVar: false
      │  │  │     └─ isIndexed: false
      │  │  ├─ body
      │  │  │  ├─ type: Block
      │  │  │  └─ statements
      │  │  │     └─ 0
      │  │  │        ├─ type: ExpressionStatement
      │  │  │        └─ expression
      │  │  │           ├─ type: BinaryOperation
      │  │  │           ├─ operator: =
      │  │  │           ├─ left
      │  │  │           │  ├─ type: TupleExpression
      │  │  │           │  ├─ components
      │  │  │           │  │  ├─ 0
      │  │  │           │  │  │  ├─ type: Identifier
      │  │  │           │  │  │  └─ name: _reserveA
      │  │  │           │  │  └─ 1
      │  │  │           │  │     ├─ type: Identifier
      │  │  │           │  │     └─ name: _reserveB
      │  │  │           │  └─ isArray: false
      │  │  │           └─ right
      │  │  │              ├─ type: FunctionCall
      │  │  │              ├─ expression
      │  │  │              │  ├─ type: MemberAccess
      │  │  │              │  ├─ expression
      │  │  │              │  │  ├─ type: Identifier
      │  │  │              │  │  └─ name: apm
      │  │  │              │  └─ memberName: getReserves
      │  │  │              ├─ arguments
      │  │  │              │  ├─ 0
      │  │  │              │  │  ├─ type: Identifier
      │  │  │              │  │  └─ name: tokenA
      │  │  │              │  └─ 1
      │  │  │              │     ├─ type: Identifier
      │  │  │              │     └─ name: tokenB
      │  │  │              └─ names
      │  │  ├─ visibility: internal
      │  │  ├─ modifiers
      │  │  ├─ override
      │  │  ├─ isConstructor: false
      │  │  ├─ isReceiveEther: false
      │  │  ├─ isFallback: false
      │  │  ├─ isVirtual: false
      │  │  └─ stateMutability: view
      │  └─ 6
      │     ├─ type: FunctionDefinition
      │     ├─ name: _swap
      │     ├─ parameters
      │     │  ├─ 0
      │     │  │  ├─ type: VariableDeclaration
      │     │  │  ├─ typeName
      │     │  │  │  ├─ type: ArrayTypeName
      │     │  │  │  ├─ baseTypeName
      │     │  │  │  │  ├─ type: ElementaryTypeName
      │     │  │  │  │  └─ name: uint
      │     │  │  │  └─ length
      │     │  │  ├─ name: amounts
      │     │  │  ├─ storageLocation: memory
      │     │  │  ├─ isStateVar: false
      │     │  │  └─ isIndexed: false
      │     │  ├─ 1
      │     │  │  ├─ type: VariableDeclaration
      │     │  │  ├─ typeName
      │     │  │  │  ├─ type: ArrayTypeName
      │     │  │  │  ├─ baseTypeName
      │     │  │  │  │  ├─ type: ElementaryTypeName
      │     │  │  │  │  └─ name: address
      │     │  │  │  └─ length
      │     │  │  ├─ name: path
      │     │  │  ├─ storageLocation: memory
      │     │  │  ├─ isStateVar: false
      │     │  │  └─ isIndexed: false
      │     │  └─ 2
      │     │     ├─ type: VariableDeclaration
      │     │     ├─ typeName
      │     │     │  ├─ type: ElementaryTypeName
      │     │     │  └─ name: address
      │     │     ├─ name: to
      │     │     ├─ storageLocation
      │     │     ├─ isStateVar: false
      │     │     └─ isIndexed: false
      │     ├─ returnParameters
      │     ├─ body
      │     │  ├─ type: Block
      │     │  └─ statements
      │     │     └─ 0
      │     │        ├─ type: ForStatement
      │     │        ├─ initExpression
      │     │        │  ├─ type: VariableDeclarationStatement
      │     │        │  ├─ variables
      │     │        │  │  └─ 0
      │     │        │  │     ├─ type: VariableDeclaration
      │     │        │  │     ├─ typeName
      │     │        │  │     │  ├─ type: ElementaryTypeName
      │     │        │  │     │  └─ name: uint
      │     │        │  │     ├─ name: i
      │     │        │  │     ├─ storageLocation
      │     │        │  │     ├─ isStateVar: false
      │     │        │  │     └─ isIndexed: false
      │     │        │  └─ initialValue
      │     │        ├─ conditionExpression
      │     │        │  ├─ type: BinaryOperation
      │     │        │  ├─ operator: <
      │     │        │  ├─ left
      │     │        │  │  ├─ type: Identifier
      │     │        │  │  └─ name: i
      │     │        │  └─ right
      │     │        │     ├─ type: BinaryOperation
      │     │        │     ├─ operator: -
      │     │        │     ├─ left
      │     │        │     │  ├─ type: MemberAccess
      │     │        │     │  ├─ expression
      │     │        │     │  │  ├─ type: Identifier
      │     │        │     │  │  └─ name: path
      │     │        │     │  └─ memberName: length
      │     │        │     └─ right
      │     │        │        ├─ type: NumberLiteral
      │     │        │        ├─ number: 1
      │     │        │        └─ subdenomination
      │     │        ├─ loopExpression
      │     │        │  ├─ type: ExpressionStatement
      │     │        │  └─ expression
      │     │        │     ├─ type: UnaryOperation
      │     │        │     ├─ operator: ++
      │     │        │     ├─ subExpression
      │     │        │     │  ├─ type: Identifier
      │     │        │     │  └─ name: i
      │     │        │     └─ isPrefix: false
      │     │        └─ body
      │     │           ├─ type: Block
      │     │           └─ statements
      │     │              ├─ 0
      │     │              │  ├─ type: VariableDeclarationStatement
      │     │              │  ├─ variables
      │     │              │  │  ├─ 0
      │     │              │  │  │  ├─ type: VariableDeclaration
      │     │              │  │  │  ├─ name: input
      │     │              │  │  │  ├─ typeName
      │     │              │  │  │  │  ├─ type: ElementaryTypeName
      │     │              │  │  │  │  └─ name: address
      │     │              │  │  │  ├─ storageLocation
      │     │              │  │  │  ├─ isStateVar: false
      │     │              │  │  │  └─ isIndexed: false
      │     │              │  │  └─ 1
      │     │              │  │     ├─ type: VariableDeclaration
      │     │              │  │     ├─ name: output
      │     │              │  │     ├─ typeName
      │     │              │  │     │  ├─ type: ElementaryTypeName
      │     │              │  │     │  └─ name: address
      │     │              │  │     ├─ storageLocation
      │     │              │  │     ├─ isStateVar: false
      │     │              │  │     └─ isIndexed: false
      │     │              │  └─ initialValue
      │     │              │     ├─ type: TupleExpression
      │     │              │     ├─ components
      │     │              │     │  ├─ 0
      │     │              │     │  │  ├─ type: IndexAccess
      │     │              │     │  │  ├─ base
      │     │              │     │  │  │  ├─ type: Identifier
      │     │              │     │  │  │  └─ name: path
      │     │              │     │  │  └─ index
      │     │              │     │  │     ├─ type: Identifier
      │     │              │     │  │     └─ name: i
      │     │              │     │  └─ 1
      │     │              │     │     ├─ type: IndexAccess
      │     │              │     │     ├─ base
      │     │              │     │     │  ├─ type: Identifier
      │     │              │     │     │  └─ name: path
      │     │              │     │     └─ index
      │     │              │     │        ├─ type: BinaryOperation
      │     │              │     │        ├─ operator: +
      │     │              │     │        ├─ left
      │     │              │     │        │  ├─ type: Identifier
      │     │              │     │        │  └─ name: i
      │     │              │     │        └─ right
      │     │              │     │           ├─ type: NumberLiteral
      │     │              │     │           ├─ number: 1
      │     │              │     │           └─ subdenomination
      │     │              │     └─ isArray: false
      │     │              ├─ 1
      │     │              │  ├─ type: VariableDeclarationStatement
      │     │              │  ├─ variables
      │     │              │  │  └─ 0
      │     │              │  │     ├─ type: VariableDeclaration
      │     │              │  │     ├─ typeName
      │     │              │  │     │  ├─ type: ElementaryTypeName
      │     │              │  │     │  └─ name: uint
      │     │              │  │     ├─ name: amountOut
      │     │              │  │     ├─ storageLocation
      │     │              │  │     ├─ isStateVar: false
      │     │              │  │     └─ isIndexed: false
      │     │              │  └─ initialValue
      │     │              │     ├─ type: IndexAccess
      │     │              │     ├─ base
      │     │              │     │  ├─ type: Identifier
      │     │              │     │  └─ name: amounts
      │     │              │     └─ index
      │     │              │        ├─ type: BinaryOperation
      │     │              │        ├─ operator: +
      │     │              │        ├─ left
      │     │              │        │  ├─ type: Identifier
      │     │              │        │  └─ name: i
      │     │              │        └─ right
      │     │              │           ├─ type: NumberLiteral
      │     │              │           ├─ number: 1
      │     │              │           └─ subdenomination
      │     │              ├─ 2
      │     │              │  ├─ type: VariableDeclarationStatement
      │     │              │  ├─ variables
      │     │              │  │  ├─ 0
      │     │              │  │  │  ├─ type: VariableDeclaration
      │     │              │  │  │  ├─ name: amount0Out
      │     │              │  │  │  ├─ typeName
      │     │              │  │  │  │  ├─ type: ElementaryTypeName
      │     │              │  │  │  │  └─ name: uint
      │     │              │  │  │  ├─ storageLocation
      │     │              │  │  │  ├─ isStateVar: false
      │     │              │  │  │  └─ isIndexed: false
      │     │              │  │  └─ 1
      │     │              │  │     ├─ type: VariableDeclaration
      │     │              │  │     ├─ name: amount1Out
      │     │              │  │     ├─ typeName
      │     │              │  │     │  ├─ type: ElementaryTypeName
      │     │              │  │     │  └─ name: uint
      │     │              │  │     ├─ storageLocation
      │     │              │  │     ├─ isStateVar: false
      │     │              │  │     └─ isIndexed: false
      │     │              │  └─ initialValue
      │     │              │     ├─ type: TupleExpression
      │     │              │     ├─ components
      │     │              │     │  ├─ 0
      │     │              │     │  │  ├─ type: FunctionCall
      │     │              │     │  │  ├─ expression
      │     │              │     │  │  │  ├─ type: TypeNameExpression
      │     │              │     │  │  │  └─ typeName
      │     │              │     │  │  │     ├─ type: ElementaryTypeName
      │     │              │     │  │  │     └─ name: uint
      │     │              │     │  │  ├─ arguments
      │     │              │     │  │  │  └─ 0
      │     │              │     │  │  │     ├─ type: NumberLiteral
      │     │              │     │  │  │     ├─ number: 0
      │     │              │     │  │  │     └─ subdenomination
      │     │              │     │  │  └─ names
      │     │              │     │  └─ 1
      │     │              │     │     ├─ type: Identifier
      │     │              │     │     └─ name: amountOut
      │     │              │     └─ isArray: false
      │     │              └─ 3
      │     │                 ├─ type: ExpressionStatement
      │     │                 └─ expression
      │     │                    ├─ type: FunctionCall
      │     │                    ├─ expression
      │     │                    │  ├─ type: MemberAccess
      │     │                    │  ├─ expression
      │     │                    │  │  ├─ type: Identifier
      │     │                    │  │  └─ name: apm
      │     │                    │  └─ memberName: swap
      │     │                    ├─ arguments
      │     │                    │  ├─ 0
      │     │                    │  │  ├─ type: Identifier
      │     │                    │  │  └─ name: amount0Out
      │     │                    │  ├─ 1
      │     │                    │  │  ├─ type: Identifier
      │     │                    │  │  └─ name: amount1Out
      │     │                    │  ├─ 2
      │     │                    │  │  ├─ type: Identifier
      │     │                    │  │  └─ name: input
      │     │                    │  ├─ 3
      │     │                    │  │  ├─ type: Identifier
      │     │                    │  │  └─ name: output
      │     │                    │  └─ 4
      │     │                    │     ├─ type: Identifier
      │     │                    │     └─ name: to
      │     │                    └─ names
      │     ├─ visibility: internal
      │     ├─ modifiers
      │     ├─ override
      │     ├─ isConstructor: false
      │     ├─ isReceiveEther: false
      │     ├─ isFallback: false
      │     ├─ isVirtual: true
      │     └─ stateMutability
      └─ kind: abstract

