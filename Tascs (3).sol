// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AbobaBank {
    // Информация о токене
    string public constant name = "AbobaCoin";
    string public constant symbol = "BOBA";
    uint8 public constant decimals = 8;
    
    // Константы
    uint256 public constant ADMIN_BALANCE = 10000 * 10**decimals; // 10,000 BOBA
    uint256 public constant USER_BALANCE = 500 * 10**decimals; // 500 BOBA
    uint256 public constant EXCHANGE_RATE = 50000000000; // 1 ETH = 50,000,000,000 BOBA
    uint256 public constant SECONDS_PER_YEAR = 31536000;
    uint256 public constant INVESTMENT_INTEREST_RATE = 12; // 12% в год
    uint256 public constant LOAN_AMOUNT = 1000000 * 10**decimals; // 1,000,000 BOBA
    uint256 public constant LOAN_INTEREST_RATE = 20; // 20% в год
    
    // Перечисления
    enum Role { None, User, Admin }
    enum LoanStatus { None, Pending, Approved, Rejected }
    
    // Структура пользователя
    struct User {
        bool exists;
        Role role;
        uint256 balance;
        bool registered;
    }
    
    // Структура инвестиции
    struct Investment {
        uint256 amount;
        uint256 lastRewardTime;
        bool active;
    }
    
    // Структура заявки на кредит
    struct LoanRequest {
        address applicant;
        uint256 amount;
        uint256 timestamp;
        LoanStatus status;
    }
    
    // Структура кредита
    struct Loan {
        uint256 principal;
        uint256 remainingDebt;
        uint256 lastPaymentTime;
        bool active;
    }
    
    // Переменные состояния
    mapping(address => User) public users;
    mapping(address => Investment) public investments;
    mapping(uint256 => LoanRequest) public loanRequests;
    mapping(address => Loan) public loans;
    
    address public owner;
    uint256 public requestCounter;
    
    // События
    event AccountCreated(address indexed user, Role role);
    event RoleChanged(address indexed user, Role newRole);
    event Deposited(address indexed user, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event InvestmentMade(address indexed user, uint256 amount);
    event InvestmentRewardClaimed(address indexed user, uint256 reward);
    event LoanRequested(address indexed applicant, uint256 requestId);
    event LoanApproved(address indexed applicant, uint256 requestId);
    event LoanRejected(address indexed applicant, uint256 requestId);
    event LoanPaid(address indexed user, uint256 amount, bool fullyPaid);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    
    // Модификаторы
    modifier onlyOwner() {
        require(msg.sender == owner, unicode"Только владелец может вызвать эту функцию");
        _;
    }
    
    modifier onlyAdmin() {
        require(users[msg.sender].role == Role.Admin, unicode"Только администратор может вызвать эту функцию");
        _;
    }
    
    modifier onlyRegistered() {
        require(users[msg.sender].registered, unicode"Пользователь не зарегистрирован");
        _;
    }
    
    // Конструктор
    constructor() {
        owner = msg.sender;
        
        // Создание аккаунта администратора
        users[msg.sender].exists = true;
        users[msg.sender].role = Role.Admin;
        users[msg.sender].balance = ADMIN_BALANCE;
        users[msg.sender].registered = true;
        
        emit AccountCreated(msg.sender, Role.Admin);
    }
    
    // Функция получения ETH
    receive() external payable {
        require(users[msg.sender].registered, unicode"Только зарегистрированные пользователи могут депозитить ETH");
        
        // Конвертация ETH в BOBA
        uint256 bobaAmount = (msg.value * EXCHANGE_RATE) / 1 ether;
        users[msg.sender].balance += bobaAmount;
        
        emit Deposited(msg.sender, bobaAmount);
    }
    
    // Резервная функция

    
    // Создание аккаунта
    function createAccount() external {
        require(!users[msg.sender].registered, unicode"Аккаунт уже зарегистрирован");
        
        users[msg.sender].exists = true;
        users[msg.sender].role = Role.User;
        users[msg.sender].balance = USER_BALANCE;
        users[msg.sender].registered = true;
        
        emit AccountCreated(msg.sender, Role.User);
    }
    
    // Изменение роли пользователя (только администратор)
    function changeUserRole(address user, Role newRole) external onlyAdmin {
        require(users[user].registered, unicode"Пользователь не зарегистрирован");
        require(newRole == Role.User || newRole == Role.Admin, unicode"Неверная роль");
        
        users[user].role = newRole;
        
        emit RoleChanged(user, newRole);
    }
    
    // Депозит ETH для получения BOBA
    function deposit() external payable onlyRegistered {
        uint256 bobaAmount = (msg.value * EXCHANGE_RATE) / 1 ether;
        users[msg.sender].balance += bobaAmount;
        
        emit Deposited(msg.sender, bobaAmount);
    }
    
    // Перевод BOBA другому пользователю
    function transfer(address to, uint256 amount) external onlyRegistered {
        require(users[to].registered, unicode"Получатель не зарегистрирован");
        require(users[msg.sender].balance >= amount, unicode"Недостаточно средств");
        
        users[msg.sender].balance -= amount;
        users[to].balance += amount;
        
        emit Transferred(msg.sender, to, amount);
    }
    
    // Сделать инвестицию
    function makeInvestment(uint256 amount) external onlyRegistered {
        require(users[msg.sender].balance >= amount, unicode"Недостаточно средств");
        require(!investments[msg.sender].active, unicode"Инвестиция уже активна");
        
        users[msg.sender].balance -= amount;
        investments[msg.sender].amount = amount;
        investments[msg.sender].lastRewardTime = block.timestamp;
        investments[msg.sender].active = true;
        
        emit InvestmentMade(msg.sender, amount);
    }
    
    // Получить награду от инвестиции
    function claimInvestmentReward() external onlyRegistered {
        require(investments[msg.sender].active, unicode"Нет активной инвестиции");
        
        uint256 reward = calculateInvestmentReward(msg.sender);
        users[msg.sender].balance += reward;
        investments[msg.sender].lastRewardTime = block.timestamp;
        
        emit InvestmentRewardClaimed(msg.sender, reward);
    }
    
    // Расчет награды от инвестиции
    function calculateInvestmentReward(address user) public view returns (uint256) {
        Investment memory investment = investments[user];
        if (!investment.active) return 0;
        
        uint256 timeElapsed = block.timestamp - investment.lastRewardTime;
        uint256 reward = (investment.amount * INVESTMENT_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
        
        return reward;
    }
    
    // Запросить кредит
    function requestLoan() external onlyRegistered {
        Loan memory userLoan = loans[msg.sender];
        require(!userLoan.active || userLoan.remainingDebt == 0, unicode"Активный кредит уже существует");
        
        uint256 requestId = requestCounter++;
        loanRequests[requestId] = LoanRequest({
            applicant: msg.sender,
            amount: LOAN_AMOUNT,
            timestamp: block.timestamp,
            status: LoanStatus.Pending
        });
        
        emit LoanRequested(msg.sender, requestId);
    }
    
    // Одобрить заявку на кредит (только администратор)
    function approveLoan(uint256 requestId) external onlyAdmin {
        LoanRequest storage request = loanRequests[requestId];
        require(request.status == LoanStatus.Pending, unicode"Неверный статус заявки");
        
        request.status = LoanStatus.Approved;
        
        // Создание кредита
        loans[request.applicant].principal = request.amount;
        loans[request.applicant].remainingDebt = request.amount;
        loans[request.applicant].lastPaymentTime = block.timestamp;
        loans[request.applicant].active = true;
        
        // Выдача денег заявителю
        users[request.applicant].balance += request.amount;
        
        emit LoanApproved(request.applicant, requestId);
    }
    
    // Отклонить заявку на кредит (только администратор)
    function rejectLoan(uint256 requestId) external onlyAdmin {
        LoanRequest storage request = loanRequests[requestId];
        require(request.status == LoanStatus.Pending, unicode"Неверный статус заявки");
        
        request.status = LoanStatus.Rejected;
        
        emit LoanRejected(request.applicant, requestId);
    }
    
    // Частичная оплата кредита
    function payLoanPartial(uint256 amount) external onlyRegistered {
        Loan storage loan = loans[msg.sender];
        require(loan.active, unicode"Нет активного кредита");
        require(users[msg.sender].balance >= amount, unicode"Недостаточно средств");
        
        // Расчет текущего долга
        uint256 currentDebt = calculateCurrentDebt(msg.sender);
        
        if (amount >= currentDebt) {
            // Полная оплата долга
            users[msg.sender].balance -= currentDebt;
            loan.remainingDebt = 0;
            loan.active = false;
            
            emit LoanPaid(msg.sender, currentDebt, true);
        } else {
            // Частичная оплата долга
            users[msg.sender].balance -= amount;
            
            // Пропорциональное обновление оставшегося долга
            loan.remainingDebt = loan.remainingDebt - (amount * loan.remainingDebt) / currentDebt;
            loan.lastPaymentTime = block.timestamp;
            
            emit LoanPaid(msg.sender, amount, false);
        }
    }
    
    // Полная оплата кредита
    function payLoanFull() external onlyRegistered {
        Loan storage loan = loans[msg.sender];
        require(loan.active, unicode"Нет активного кредита");
        
        uint256 currentDebt = calculateCurrentDebt(msg.sender);
        require(users[msg.sender].balance >= currentDebt, unicode"Недостаточно средств");
        
        users[msg.sender].balance -= currentDebt;
        loan.remainingDebt = 0;
        loan.active = false;
        
        emit LoanPaid(msg.sender, currentDebt, true);
    }
    
    // Расчет текущего долга
    function calculateCurrentDebt(address user) public view returns (uint256) {
        Loan memory loan = loans[user];
        if (!loan.active || loan.remainingDebt == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - loan.lastPaymentTime;
        uint256 interest = (loan.remainingDebt * LOAN_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
        
        return loan.remainingDebt + interest;
    }
    
    // Вывод ETH из контракта (только владелец)
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, unicode"Нет ETH для вывода");
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, unicode"Перевод не удался");
        
        emit EtherWithdrawn(owner, balance);
    }
    
    // Функции просмотра
    function getUserBalance(address user) external view returns (uint256) {
        return users[user].balance;
    }
    
    function getUserRole(address user) external view returns (Role) {
        return users[user].role;
    }
    
    function getInvestmentInfo(address user) external view returns (uint256 amount, uint256 lastRewardTime, bool active) {
        Investment memory investment = investments[user];
        return (investment.amount, investment.lastRewardTime, investment.active);
    }
    
    function getLoanInfo(address user) external view returns (uint256 principal, uint256 remainingDebt, uint256 lastPaymentTime, bool active) {
        Loan memory loan = loans[user];
        return (loan.principal, loan.remainingDebt, loan.lastPaymentTime, loan.active);
    }
    
    function getLoanRequest(uint256 requestId) external view returns (address applicant, uint256 amount, uint256 timestamp, LoanStatus status) {
        LoanRequest memory request = loanRequests[requestId];
        return (request.applicant, request.amount, request.timestamp, request.status);
    }
}
