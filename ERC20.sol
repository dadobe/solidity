// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

// Interfaces para los métodos del Token - interface ERC20
interface IERC20{

    // Función que devuelve la cantidad de Tokens en existencia
    function totalSupply() external view returns (uint256);

    // Función que devuelve la cantidad de tokesn para una dirección indicada por parámetro
    function balanceOf(address account) external view returns (uint256);

    // Función que devuelve el número de tokens que el spender podrá gastar en nombre del owner
    function allowance(address owner, address spender) external view returns (uint256);

    //Comprobaciones booleanas
    // Función que devuelve un valor BOOL resultado de la OPERACION (transferencia) indicada -- cambio de propietario
    function transfer(address recipient, uint256 amount) external returns (bool); 

    // Funcion ayuda para realizar la transferencia entre cliente y Disney
    function transfer_Disney(address _cliente, address receiver, uint256 numTokens) external returns (bool);

    //Devuelve un valor BOOL con el resultado de la operacion de gasto -- cedo parte de mis tokens para que alguien en mi nombre los mueva como si fuera un broker
    function approve(address spender, uint256 amount) external returns (bool);

    //Devuelve un valor BOOL con el resultado de la operacion de paso de una cantidad de tokens
    // usando el método ALLOWANCE()
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Evento que se debe emitir cuando una cantidad de tokens pase de un ORIGEN a un DESTINO
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Evento que se debe emitir cuando se establece una asignacion con el método ALLOWANCE()
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// owner --> 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// buyer --> 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// delegate --> 0x617F2E2fD72FD9D5503197092aC168c91465E7f2

// Implementacion de los métodos de la interface
contract ERC20Basic is IERC20{

    // Constantes del smart contract
    string public constant name ="ERC20AZ";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;

    // ----------------------    Eventos    ----------------------  //
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
    // ----------------------  Fin eventos  ----------------------  //

    // Con esto nos aseguramos que las operaciones implementadas en SafeMATH sean válidas
    using SafeMath for uint256;

    // Mappings
    mapping(address => uint) balances; // a cada direccion le corresponden X tokens
    mapping(address => mapping (address => uint)) allowed; // a cada direccion le corresponde un conjunto de direcciones con cantidad de tokens a cada una de ellas
    uint256 totalSupply_; // total de Tokens

    //Constructor -- momento en que se crea la moneda virtual
    constructor(uint256 initialSupply) public{
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_; //asignamos al emisor del mensaje la cantidad global de TOKENS
    }

    function totalSupply() public override view returns (uint256){
        return totalSupply_;
    }

    //Funcion de ayuda para incrementar Tokens
    function increaseTotalSupply(uint newTokensAmount) public {
        totalSupply_ += newTokensAmount;
        balances[msg.sender] += newTokensAmount; //a quien se le deben atribuir newTokensAmount
    }

    //Funcion que devuelve el total de tokens actuales
    function balanceOf(address tokenOwner) public override view returns (uint256){ //Tokens propios (no tokens en nombre de otra persona)
        return balances[tokenOwner];
    }

    //Funcion de ayuda para permitir gastar en nombre de otro
    function allowance(address owner, address delegate) public override view returns (uint256){
        return allowed[owner][delegate];
    }

    // view no hace falta por ser una operacion BOOL
    function transfer(address recipient, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[msg.sender]); // necesario para evitar sacar de mi balance un numTokens superior
        balances[msg.sender] = balances[msg.sender].sub(numTokens); // restamos los tokens de mi balance de tokens actual
        balances[recipient] = balances[recipient].add(numTokens); // añadimos los tokens (que nos quitamos previamente) al recipient
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    // Funcion ayuda para realizar la transferencia entre cliente y Disney
    function transfer_Disney(address _cliente, address receiver, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[_cliente]);
        balances[_cliente] = balances[_cliente].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(_cliente, receiver, numTokens);
        return true;
    }

    // Yo como propietario de un numero de tokens permito que un delegate disponga de cierta cantidad
    function approve(address delegate, uint256 numTokens) public override returns (bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    // Funcion que no es una transferencia DIRECTA entre onwer y buyer, va a traves de un delegate -- venta indirecta
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool){
        require(numTokens <= balances[owner]); // requerimiento para que el numero de tokens sea menor o igual al de tokens de los que dispone
        require(numTokens <= allowed[owner][msg.sender]); // requerimiento para que el numero de tokens sea <= a los permitidos para los que disponia el onwer y los que nos haya cedido a nosotros como intermediario de la venta [msg.sender]
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens); // como intermediario me quito el numero de tokens que el propietario me ha cedido previamente
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}