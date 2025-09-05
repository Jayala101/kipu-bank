// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
   Contrato KipuBank
   Un contrato mediante solidity que permite al usuario 
   depositar y retirar ethereum con límites de transacción 
   y un tope máximo de depósitos.
 */
contract KipuBank {
    // Estructura para guardar los tipos de datos
    struct UserInfo {
        uint256 balance;
        uint256 depositCount;
        uint256 withdrawalCount;
    }

    // Variables inmutables 
    address public immutable i_owner;
    uint256 public immutable i_bankCap;
    uint256 public immutable i_maxWithdrawalPerTx;
    
    // Variables de estado
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public totalTransactions;
    
    // Mapeos
    mapping(address => UserInfo) private s_userInfo;
    
    // Eventos
    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed user, uint256 amount, uint256 newBalance);
    event BankCapReached(uint256 timestamp);
    
    // Errores personalizados
    error KipuBank__NotOwner();
    error KipuBank__ZeroAmount();
    error KipuBank__ExceedsBankCap(uint256 current, uint256 attempted);
    error KipuBank__ExceedsWithdrawalLimit(uint256 attempted, uint256 limit);
    error KipuBank__InsufficientBalance(uint256 available, uint256 requested);
    error KipuBank__TransferFailed();
    
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert KipuBank__NotOwner();
        _;
    }
    
    modifier nonZeroAmount() {
        if (msg.value == 0) revert KipuBank__ZeroAmount();
        _;
    }
    
    constructor(uint256 bankCap, uint256 maxWithdrawalPerTx) {
        if (maxWithdrawalPerTx == 0 || bankCap == 0) revert KipuBank__ZeroAmount();
        if (maxWithdrawalPerTx > bankCap) revert KipuBank__ExceedsWithdrawalLimit(maxWithdrawalPerTx, bankCap);
        
        i_owner = msg.sender;
        i_bankCap = bankCap;
        i_maxWithdrawalPerTx = maxWithdrawalPerTx;
    }
    
    /*
       Función para depositar ETH en el banco
       El usuario tiene un limite para depositar (10 ETH) 
       y realiza un evento para mostrar un deposito exitoso
     */
    function deposit() external payable nonZeroAmount {
        if (totalDeposits + msg.value > i_bankCap) {
            revert KipuBank__ExceedsBankCap(totalDeposits, msg.value);
        }
        
        _processDeposit(msg.sender, msg.value);
        
        emit Deposited(msg.sender, msg.value, s_userInfo[msg.sender].balance);
        
        if (totalDeposits == i_bankCap) {
            emit BankCapReached(block.timestamp);
        }
    }
    
    /*
       Función para retirar ETH del banco
       El usuario tiene el limite de 1 ETH para retirar por transacción
       y realiza un evento para mostrar un retiro exitoso
     */
    function withdraw(uint256 amount) external {
        if (amount == 0) revert KipuBank__ZeroAmount();
        if (amount > i_maxWithdrawalPerTx) {
            revert KipuBank__ExceedsWithdrawalLimit(amount, i_maxWithdrawalPerTx);
        }
        
        UserInfo storage userInfo = s_userInfo[msg.sender];
        if (userInfo.balance < amount) {
            revert KipuBank__InsufficientBalance(userInfo.balance, amount);
        }
        
        // Actualizar estado antes de la transferencia (CEI pattern)
        unchecked {
            userInfo.balance -= amount;
            userInfo.withdrawalCount++;
            totalDeposits -= amount;
            totalWithdrawals += amount;
            totalTransactions++;
        }
        
        // Realizar la transferencia
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert KipuBank__TransferFailed();
        
        emit Withdrawn(msg.sender, amount, userInfo.balance);
    }
    
    /*
      Obtiene la información completa de un usuario
      Usa la dirección del usuario para retornar la estructura 
      con la información del usuario (balance, depósitos y retiros)
     */
    function getUserInfo(address user) external view returns (UserInfo memory userInfo) {
        return s_userInfo[user];
    }
    
    //Obtiene el balance del contrato
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /*
       Función privada para procesar depósitos
       usando la dirección del usuario y cantidad a depositar
     */
    function _processDeposit(address user, uint256 amount) private {
        UserInfo storage userInfo = s_userInfo[user];
        unchecked {
            userInfo.balance += amount;
            userInfo.depositCount++;
            totalDeposits += amount;
            totalTransactions++;
        }
    }
    
    // Función de fallback que acepta ETH
    receive() external payable {
        this.deposit();
    }
}