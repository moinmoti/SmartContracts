pragma solidity ^0.4.10;

contract game {

    uint public reward;
    uint public fee;
    int[3][3] checkWinner;
    uint inputDeadline;
    uint revealDeadline;

    address public moderator;

    struct Player {
        address id;
        int choice;
    }

    Player[] public players;

    modifier onlyBefore (uint _time) { require(now < _time); _; }
    modifier onlyAfter (uint _time) { require(now > _time); _; }
    modifier onlyModerator () { require(msg.sender == moderator); _; }
    modifier isPlayer () { require(msg.sender == players[0].id || msg.sender == players[1].id); _; }

    function game (uint _fee, address player0Address, address player1Address, uint inputTime) {
        moderator = msg.sender;
        inputDeadline = now + inputTime;
        fee = _fee;
        players.push(Player({
            id: player0Address,
            choice: -1
        }));
        players.push(Player({
            id: player1Address,
            choice: -1
        }));

        for (uint i = 0; i < 3; i++) checkWinner[i][i] = -1;
        checkWinner[0][1] = 1;
        checkWinner[0][2] = 0;
        checkWinner[1][0] = 0;
        checkWinner[1][2] = 1;
        checkWinner[2][0] = 1;
        checkWinner[2][1] = 0;
    }

    function inputChoice (bytes32 choice)
        payable
        isPlayer
        onlyBefore(inputDeadline)
        returns (bool)
    {
        Player player = (msg.sender == players[0].id) ? players[0] : players[1];
        require(msg.value > fee);
        player.choice = (choice == "rock") ? 0 : ((choice == "paper") ? 1 : 2);
        return true;
    }
}
