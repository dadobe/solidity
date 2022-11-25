// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";


// Tokens desplegados -> 0xdD870fA1b7C4700F2BD7f44238821C26f7392148

contract DisneyTokens{

    // ----------------------  DECLARACIONES INICIALES ----------------------  

    //Instancia del contrato token
    ERC20Basic private token;

    //Direccion de owner (Disney)
    address payable public owner; //direccion para realizar pagos

    //Constructor
    constructor() public{
        token = new ERC20Basic(10000); //Creacion inicial de 10.000 Tokens
        owner = msg.sender; 
    }

    // Estructura de datos para almacenar a los clientes de Disney
    struct cliente{
        uint tokens_comprados;
        string [] atracciones_disfrutadas;
    }

    //Mapping para el registro de clientes
    mapping(address => cliente) public Clientes;

    // ----------------------  Gestion de TOKENS ----------------------  

    // Relacionamos valor del token con moneda ETHEREUM
    function PrecioTokens(uint _numTokens) internal pure returns (uint){
        return _numTokens*(1 ether); //conversion de tokens a ethers: 1token -> 1ether
    }

    // Funcion en la cual un cliente transfomre su moneda en tokens para las atracciones
    function CompraTokens(uint _numTokens) public payable {
        //establecer precio tokens
        uint coste = PrecioTokens(_numTokens);
        //requerimiento para proceder al cambio de divisa
        require(msg.value >= coste, "Compra menos Tokens o paga con más ETHERS");
        //Diferencia de lo que el cliente paga
        uint returnValue = msg.value - coste;
        // Disney retorna la cantidad de Ethers al cliente
        msg.sender.transfer(returnValue);
        // Obtener el Tokens Total disponibles
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Compra un numero menor de Tokens.");
        // Transferencia de tokens de Disney al Cliente
        token.transfer(msg.sender, _numTokens);
        // Almacenamos en un registro los Tokens comprados
        Clientes[msg.sender].tokens_comprados += _numTokens;
    }

    // Funcion para ver el numero de tokens disponibles en el smartcontract -- balance de tokens del contrato Disney
    function balanceOf() public view returns (uint){
        return token.balanceOf(address(this));
    }

    // Funcion para visualizar el número de tokens disponibles de un cliente
    function MisTokens() public view returns (uint){
        return token.balanceOf(msg.sender);
    }

    // Funcion para geenrar más tokens en funcion de la demanda
    function GeneraTokens(uint _numTokens) public Unicamente(msg.sender){ // Unicamente es un modificador
        token.increaseTotalSupply(_numTokens);
    }

    // Modificador para contorla las funciones ejecutables por Disney
    modifier Unicamente(address _direccion) {
        require(_direccion == owner, "No tienes permisos para ejecutar esta funcion");
        _;
    }

    // ----------------------  Gestion de DISNEY ----------------------  

    // Eventos
    event disfruta_atraccion(string); //le pasamos el nombre de la atrracion a disfrutar
    event nueva_atraccion(string, uint);
    event baja_atraccion(string);

    event muestra_attraccion(string[]);
    event disfruta_menu(string, uint, address);
    event nuevo_menu(string, uint);

// ---------------------------------- Estructuras ----------------------------------

    // Estructura de datos de la atraccion
    struct atraccion {
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }

    // Estructura de datos del menu de comida
    struct menu {
        string nombre_menu;
        uint precio_menu;
        bool estado_menu;
    }

// ---------------------------------- MAPPINGS ----------------------------------

    // Mapping para relacionar una atraccion con una estructura de datos de la atraccion
    mapping(string => atraccion) public MappingAtracciones;

    // Array para almacenar el nombre de las atracciones
    string [] Atracciones;

    // Mapping para relacionar un cliente con las atracciones disfrutadas en DISNEY -- Historial del cliente
    mapping(address => string[]) public HistorialAtracciones; // "address - cliente" se mapea con "string - array de atracciones"

    // Mapping para relacionar un menú con una estructura de datos del menú
    mapping(string => menu) public MappingMenus;

    // Array para almacenar el nombre del menú
    string [] Menus;

    // Mapping para relacionar un cliente con los menús disfrutados
    mapping(address => string[]) public HistorialComida;


// -------------------------- Funciones ATRACCIONES -------------------------- 

    //Funcion que crea una nueva atraccion -- solamente ejecutable por DISNEY, de ahi el modificador "Unicamente"
    function NuevaAtraccion(string memory _nombreAtraccion, uint _precio) public Unicamente(msg.sender){
        // Crear la atraccion
        MappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion, _precio, true);
        // Almacenar en un array el nombre de la atraccion
        Atracciones.push(_nombreAtraccion);
        // Emision del evento para la nueva atraccion
        emit nueva_atraccion(_nombreAtraccion, _precio);
    }

    // Funcion para dar de baja una atraccion existente
    function BajaAtraccion(string memory _nombreAtraccion) public Unicamente(msg.sender){
        // Cambiar estado el parámetor BOOL -> si es FALSE, atraccion no está en uso
        MappingAtracciones[_nombreAtraccion].estado_atraccion = false; //".estado_atraccion" es para acceder a ese campo de ATRACCION
        // Emsion del evento para la baja de la atraccion
        emit baja_atraccion(_nombreAtraccion);
    }

    /*
    // Funcion para dar de baja una atraccion existente
    function QuitarAtraccion(string memory _nombreAtraccion, uint _precio) public Unicamente(msg.sender){
        //Eliminar atraccion
        Atracciones.pop();
        // Actualizar el mapping
        MappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion, _precio, false);
        emit baja_atraccion(_nombreAtraccion);
    }


    // Funcion listar atracciones y su estado
    function ListarAtracciones() public Unicamente(msg.sender){
        atraccion [] lista = MappingAtracciones;
        event muestra_attraccion(lista);
    }
    */

    // Funcion para mostrar TODAS las atracciones existentes actualmente
    function MostrarAtracciones() public view returns (string[] memory){
        return Atracciones;
    }

    // Funcion para subirse a una traccion y realizar el pago en Tokens
    function SubirseAtraccion(string memory _nombreAtraccion) public {
        //Precio de la atraccion en Tokens
        uint tokensAtraccion = MappingAtracciones[_nombreAtraccion].precio_atraccion;
        // Verificacion del estado de la atraccion - si esta disponible para su uso
        require(MappingAtracciones[_nombreAtraccion].estado_atraccion == true, "Atraccion no disponible en estos momentos");
        // Verificacion del numero de tokens disponibles por el cliente para usar la atraccion
        require(tokensAtraccion <= MisTokens(), "Necesitas más tokens para subirte a esta eatracción.");
        // Transferencia de tokens entre persona que se quiere subir a la atraccion y Disney
        token.transfer_Disney(msg.sender, address(this), tokensAtraccion);
        // Historial de atracciones del cliente
        HistorialAtracciones[msg.sender].push(_nombreAtraccion);
        //Emision del evento
        emit disfruta_atraccion(_nombreAtraccion);
    }

    // Funcion para visualizar el historial completo de atraccions disfrutadas pro un cliente
    function Historico() public view returns (string [] memory){
        return HistorialAtracciones[msg.sender];
    }

    // Funcion que permite devolver los tokens sobrante
    function DevolverTokens(uint _numTokens) public payable {
        //verificar que el numero de tokens a devlver es positivo
        require(_numTokens > 0, "Necesitas estar en un balance POSITIVO para devolver Tokens.");
        // El susuario debe de tener el numero de tokens a devolver - no devolver mas de lo que se tiene
        require(_numTokens <= MisTokens(), "No tienes tokens suficientes para devolver.");
        // El cliente devuelve los tokens
        token.transfer_Disney(msg.sender, address(this), _numTokens);
        // Disney devuelve tokens en forma de Ethers al cliente
        msg.sender.transfer(PrecioTokens(_numTokens));

    }

// -------------------------- Funciones MENU -------------------------- 

    // Funcion para mostrar TODOS las menus existentes actualmente
    function MostrarMenus() public view returns (string[] memory){
        return Menus;
    }

    // Funcion para crear menu
    function CrearMenu(string memory _nombreMenu, uint256 _precio) public Unicamente(msg.sender){
        // Instanciacion del nuevo menu
        MappingMenus[_nombreMenu] = menu(_nombreMenu, _precio, true);
        // Push del menu al array
        Menus.push(_nombreMenu);
        // Evento del nuevo menu
        emit nuevo_menu(_nombreMenu, _precio);
    }

    // Funcion para disfrutar un menu y realizar el pago en Tokens
    function ComprarMenu(string memory _nombreMenu) public {
        //Precio del menú en Tokens
        uint tokensMenu = MappingMenus[_nombreMenu].precio_menu;
        // Verificacion del estado del menú - si esta disponible
        require(MappingMenus[_nombreMenu].estado_menu == true, "Menú no disponible en estos momentos");
        // Verificacion del numero de tokens disponibles por el cliente para comprar menú
        require(tokensMenu <= MisTokens(), "Necesitas más tokens para comprar éste menú.");
        // Transferencia de tokens entre persona que compra el menú y Disney
        token.transfer_Disney(msg.sender, address(this), tokensMenu);
        // Historial de menus del cliente
        HistorialComida[msg.sender].push(_nombreMenu);
        //Emision del evento
        emit disfruta_menu(_nombreMenu, tokensMenu, msg.sender);
    }

    function Comidas() public view returns (string [] memory){
        return HistorialComida[msg.sender];
    }
}