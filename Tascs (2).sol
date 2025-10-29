// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Ровчак Матвей Task1

contract Task2 {
    struct User {
        uint256 id;
        string login;
        string password;
        uint256 balance;
        bool isOwner;
        address userAddress;
    }

    address public owner;
    mapping(address => User) private users;
    mapping(string => address) private loginToAddress;
    
    // Счётчик ID
    uint256 private nextId = 1;

    // Модификаторы
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier onlyRegisteredUser() {
        require(users[msg.sender].userAddress != address(0), "User not registered");
        _;
    }

    constructor(string memory login, string memory password) {
        owner = msg.sender;
        users[owner] = User({
            id: nextId++,
            login: login,
            password: password,
            balance: 100_000,
            isOwner: true,
            userAddress: owner
        });
        loginToAddress[login] = owner;
    }

    // --- Функции владельца ---
    // 1. Снять все ETH с контракта
    function withdrawAll() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // 2. Передать владение (новый владелец должен быть зарегистрирован)
    function transferOwnership(string memory newOwnerLogin) external onlyOwner {
        address newOwner = loginToAddress[newOwnerLogin];
        require(newOwner != address(0), "New owner not registered");
        require(!users[newOwner].isOwner, "New owner is already owner");

        // Сбрасываем старого владельца
        users[owner].isOwner = false;
        // Назначаем нового
        owner = newOwner;
        users[newOwner].isOwner = true;
    }

    // 3. Посмотреть информацию о пользователе по логину
    function getUserInfo(string memory login) external onlyOwner view returns (User memory) {
        address userAddress = loginToAddress[login];
        require(userAddress != address(0), "User not found");
        return users[userAddress];
    }

    // --- Функции пользователей ---
    // 1. Регистрация (только для новых пользователей)
    function register(string memory login, string memory password) external {
        require(users[msg.sender].userAddress == address(0), "Already registered");
        require(loginToAddress[login] == address(0), "Login taken");

        users[msg.sender] = User({
            id: nextId++,
            login: login,
            password: password,
            balance: 5_000,
            isOwner: false,
            userAddress: msg.sender
        });
        loginToAddress[login] = msg.sender;
    }

    // 2. Авторизация (проверка пароля)
    function authenticate(string memory password) external onlyRegisteredUser view returns (bool) {
        string memory storedPassword = users[msg.sender].password;
        return keccak256(bytes(storedPassword)) == keccak256(bytes(password));
    }

    // 3. Посмотреть свой баланс
    function getMyBalance() external onlyRegisteredUser view returns (uint256) {
        return users[msg.sender].balance;
    }

    // 4. Посмотреть свой ID
    function getMyId() external onlyRegisteredUser view returns (uint256) {
        return users[msg.sender].id;
    }
}