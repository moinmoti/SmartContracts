pragma solidity ^0.4.10;

contract game {

    /*Declare the variables to be used in the program*/
    /*uint : unsigned integer*/
    uint public fee;
    int[3][3] checkWinner;

    /*we will use unix timestamps to keep account of time*/
    uint inputDeadline;
    uint revealDeadline;

    /*to check the number of players registering for the game*/
    uint numPlayers;

    /*this variable holds the address of the moderator which will run the game*/
    address public moderator;

    /*This Structure which will represent each player in the game*/
    struct Player {
        address account; // holds the player's address
        bytes32 hash_value; // encrypred hash value of the player's choice
        int choice; // player's choice to be revealed  later
    }

    /*only 2 players allowed to play the game at a time*/
    Player[2] public players;


    /*Modifiers are a convenient way to validate inputs to
    functions. `onlyBefore` is applied to `bid` below:
    The new function body is the modifier's body where
    is replaced by the old function body.*/

    // ensures the call is made is before certain time
    modifier onlyBefore (uint _time) { require(now < _time); _; }

    // ensures the call is made is after certain time
    modifier onlyAfter (uint _time) { require(now > _time); _; }

    // ensures only the moderator is calling the function
    modifier onlyModerator () { require(msg.sender == moderator); _; }

    // ensures one of the player is calling the function
    modifier isPlayer () { require(msg.sender == players[0].account || msg.sender == players[1].account); _; }

    /*This declares a state variable that stores pending returns for each possible address*/
    mapping (address => uint) pendingReturns;

    /*Events that will be fired on change
    These events can be used as normal javascript events in the DApp (Decentralized Application)*/
    event gameEnded (address winner, uint amount); // event when the game ends with a winner
    event gameDrawn (); // event when a game ends in a draw


    /*The following is a so-called natspec comment,
    recognizable by the three slashes.
    It will be shown when the user is asked to
    confirm a transaction.*/

    /// Create a Rock Paper Scissor game with a specified entry fee
    function game (uint _fee, uint inputTime, uint revealTime) {

        /*you can access the info on the call made to this function using msg object*/
        moderator = msg.sender; // store the address of the person who called this method
        inputDeadline = now + inputTime;
        revealDeadline = inputDeadline + revealTime;
        fee = _fee;

        /*Encode the rules of the game in this maatrix
        "1" means player1 won
        "2" means player2 won
        "-1" means draw*/
        for (var i = 0; i < 3; i++) checkWinner[i][i] = -1;
        checkWinner[0][1] = 1;
        checkWinner[0][2] = 0;
        checkWinner[1][0] = 0;
        checkWinner[1][2] = 1;
        checkWinner[2][0] = 1;
        checkWinner[2][1] = 0;
    }

    /// Register for the Rock Paper Scissor Game
    /// Your input choice will be locked until the
    /// reveal function is called which is possible
    /// only after input deadline is over
    /// Provide hash_value = keccak256(choice, secret)
    function inputChoice (bytes32 hash_value)

        // The keyword "payable" is required for the function
        // to be able to receive Ether.
        payable

        // allow registration only before the deadline is met
        onlyBefore(inputDeadline)
    {
        // require: If the argument of `require` evaluates to `false`,
        // it terminates and reverts all changes to
        // the state and to Ether balances. It is often
        // a good idea to use this if functions are
        // called incorrectly. But watch out, this
        // will currently also consume all provided gas
        // (this is planned to change in the future).
        require(numPlayers < 3);

        /*allow registration only when sufficient payment is made */
        require(msg.value >= fee);

        /*Register the player once the payment is verified */
        players[numPlayers++].account = msg.sender;
        players[numPlayers].hash_value = hash_value;
        players[numPlayers].choice = -1;

        /*Sending back the money by simply using
        highestBidder.send(highestBid) is a security risk
        because it can be prevented by the caller by e.g.
        raising the call stack to 1023. It is always safer
        to let the recipients withdraw their money themselves*/
        // store the amount sender should withdraw
        pendingReturns[msg.sender] = msg.value - fee;
    }

    /// Reveal your choice
    /// Your choice will be considered valid only if it matches
    /// the choice you provided  earlier
    function reveal (bytes32 choice, bytes32 secret)
        onlyAfter(inputDeadline)
        onlyBefore(revealDeadline)
        isPlayer
        returns (bool)
    {
        var player = (msg.sender == players[0].account) ? players[0] : players[1];

        /*if the other player didn't even show up for playing
        no need to further continue the game, give the refund
        to the player*/
        if (numPlayers < 2) pendingReturns[msg.sender] += this.balance;
        else if (player.hash_value == keccak256(choice, secret)) {
            player.choice = (choice == "rock") ? 0 : ((choice == "paper") ? 1 : 2);
            return true;
        }
        return false;
    }


    /*It is a good guideline to structure functions that interact
    with other contracts (i.e. they call functions or send Ether)
    into three phases:
    1. checking conditions
    2. performing actions (potentially changing conditions)
    3. interacting with other contracts
    If these phases are mixed up, the other contract could call
    back into the current contract and modify the state or cause
    effects (ether payout) to be perfromed multiple times.
    If functions called internally include interaction with external
    contracts, they also have to be considered interaction with
    external contracts.*/
    function getWinner()

        // 1. Conditions
        onlyModerator
        onlyAfter(revealDeadline)
        returns (bool)
    {
        require(players[0].choice >= 0 || players[1].choice >= 0);

        // 2. Effects

        /*In case one of the players (a dishonest player) backed out at the moment
        of revealing their choice, the other player is given the total reward*/

        if (players[0].choice < 0) pendingReturns[players[1].account] += this.balance;
        else if (players[1].choice < 0) pendingReturns[players[0].account] += this.balance;
        else {

            /*Given both the players played honestly, their choices are evaluated
            and the winner is declared if its not a draw */

            var result = checkWinner[uint(players[0].choice)][uint(players[1].choice)];
            if (result < 0) {
                pendingReturns[players[0].account] += this.balance/2;
                pendingReturns[players[1].account] += this.balance/2;
                gameDrawn;
            } else {
                var winner = players[uint(result)];

                // 3. Interactions
                winner.account.transfer(this.balance);

                // Trigger the event
                gameEnded(winner.account, this.balance);
            }
            return true;
        }
        return false;
    }

    /// Withdraw leftover amount
    function withdraw() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {

            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {

                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
}
