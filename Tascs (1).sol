// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Ровчак Матвей Task1

contract Task1 {
    // 1. Обьявление переменных
    uint number = 22;
    string text = "Hello world";
    bool flag = true;
    address Tom = 0x9f44852E86D85c421Af26cF233105D959dED3D42;
    uint256[] numbersArray = [1, 2, 3];
    
    struct User {
        uint id;
        string name;
        address userAddress;
        bool isAuth;
    }
 
    mapping(uint => User) public users;


    // 2. Функции возврата переменных
    function getNumber() public view returns (uint) {
        return number;
    }

    function getText() public view returns (string memory) {
        return text;
    }

    function getFlag() public view returns (bool) {
        return flag;
    }

    function getOwner() public view returns (address) {
        return Tom;
    }

    function getNumbersArray() public view returns (uint256[] memory) {
        return numbersArray;
    }


    // 3. Функции для работы со структурой и mapping
    function addUser(
        uint256 id,
        string memory name,
        address user,
        bool isAuth
    ) public {
        users[id] = User(id, name, user, isAuth);
    }
    function getUser(uint256 id) public view returns (User memory) {
        return users[id];
    }


    // 4. Функции для работы с массивом добавление/удаление
    function addToArray(uint256 value) public {
        numbersArray.push(value);
    }
    function removeLastFromArray() public {
        numbersArray.pop();
    }

    // 5. Функции для добавления в массив с разными циклами
    function addWithForLoop(uint256[] memory values) public returns (uint256[] memory) {
        for (uint256 i = 0; i < values.length; i++) {
            numbersArray.push(values[i]);
        }
        return numbersArray;
    }

    function addWithWhileLoop(uint256[] memory values) public returns (uint256[] memory) {
        uint256 i = 0;
        while (i < values.length) {
            numbersArray.push(values[i]);
            i++;
        }
        return numbersArray;
    }

    function addWithDoWhileLoop(uint256[] memory values) public returns (uint256[] memory) {
        uint256 i = 0;
        do {
            numbersArray.push(values[i]);
            i++;
        } while (i < values.length);
        return numbersArray;
    }


    // Банковская система
    struct Profile {
        string name;
        uint id;
        string login;
        string password;
        uint balance;
    }
    mapping(uint256 => Profile) profiles;
    function signUp(string memory name, uint id, string memory login, string memory password) public {
        require(users[id].userAddress == address(0), "User with this ID already exists");
        profiles[id] = Profile(name, id, login, password, 0);
    }

    function getUserInfo(uint id) public view returns (Profile memory) {
        return profiles[id];
    }

    function deposit(uint id, uint amount) public payable {
        require(amount > 0, "Deposit amount must be greater than 0");
        profiles[id].balance += amount;
    }

    function withdraw(uint id, uint amount) public payable {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(amount <= profiles[id].balance, "Insufficient balance");
        profiles[id].balance -= amount;
    }

}