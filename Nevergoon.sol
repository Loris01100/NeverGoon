// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//on donne un nom de contrat ERC20 (norme)
//dans ce cas NeverGoon
contract NeverGoon is ERC20 {
    using SafeERC20 for IERC20;
    
    //adresse du propriétaire du contrat
    address public owner;
    
    //événements émis lors du brûlage
    event Burn(address indexed burner, uint256 value);

    //modificateur pour restreindre l'accès aux seules fonctions du propriétaires
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    //Constructeur qui initialise le token avec l'approvisionnement initial
    //il est appelé une seule fois : quand le contrat est déployé (déployé en vrai pas une vm)
    //initialSupply c'est le nombre de token créer au total
    //Pour faire simple, ça définit le propriétaire du contrat (celui qui déploie)
    //on initialise le nombre de token total
    //le déployeur est crédité car déployé un contrat coûte de l'argent (dépend de la blockchain)
    constructor(uint256 initialSupply) ERC20("NeverGoon", "GOON") {
        owner = msg.sender;
        uint256 initialAmount = initialSupply * 10 ** uint256(decimals());
        _mint(msg.sender, initialAmount);
    }

    //permet au propriétaires de créer de nouveaux tokens (c'est le minage)
    //peut être appelé uniquement par le propriétaire du contrat
    //value : nombre de tokens à créer
    //value doit être supérieur à 0
    function mint(uint256 value) public onlyOwner returns (bool) {
        require(value > 0, "Amount must be greater than 0");
        _mint(owner, value);
        return true;
    }

    //permet de brûler ses propres tokens
    //peut être appelé par n'importe quel propriétaire de token
    //value : nombre de token que l'on veut brûler (détruire)
    //l'appellant doit avoir au moins des tokens
    //ça réduit le totalSupply du contrat (token en circulation)
    //réduit le solde de l'utilisateur
    function burn(uint256 value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient tokens to burn");
        _burn(msg.sender, value);
        emit Burn(msg.sender, value);
        return true;
    }

    //permet de brûler les tokens d'une autre adresse avec autorisation préalable
    //from : adresse dont on veut brûler des tokens
    //value : nombre de token que l'on veut brûler
    //l'adresse from doit avoir des tokens en stocks
    //l'appelant doit avoir une allocation suffisante (allowance >= value)
    //Une autorisation doit être fourni au préalable
    function burnFrom(address from, uint256 value) public returns (bool) {
        require(balanceOf(from) >= value, "Insufficient tokens to burn");
        require(allowance(from, msg.sender) >= value, "Allowance exceeded");
        
        _approve(from, msg.sender, allowance(from, msg.sender) - value);
        _burn(from, value);
        emit Burn(from, value);
        return true;
    }

    //Permet de déposer des tokens externes dans ce contrat
    //peut être appelée par n'importe quel utilisateur
    //permet à n'importe qui de déposer d'autres tokens ERC20 dans ce contrat
    //token: adresse du contrat du token ERC20 externe
    //amount: nombre de tokens externes à déposer
    //l'adresse du token ne doit pas être adresse zéro
    //amount doit être > 0
    //l'utilisateur doit d'abord avoir approuvé ce contrat pour dépenser ses tokens
    //l'utilisateur doit avoir au moins "amount" du token externe
    function depositExternalToken(address token, uint256 amount) public returns (bool) {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return true;
    }

    //permet au propriétaire de retirer des tokens externes du contrat
    //peut être appelé uniquement par le propriétaire du contrat
    //token : adresse du contrat du token ERC20 à retirer
    //to : adresse destinataire qui recevra les tokens
    //amount : nombre de token à retirer
    //l'adresse du token ne doit pas être adresse zéro
    //l'adresse destinataire ne doit pas être adresse zéro
    //amount doit être > 0
    //le contrat doit avoir au moins "amount" du token à retirer
    function withdrawExternalToken(address token, address to, uint256 amount) public onlyOwner returns (bool) {
        require(token != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).safeTransfer(to, amount);
        return true;
    }

    //permet au propriétaire d'approuver un tiers à dépenser des tokens externes stockés dans ce contrat
    //peut être appelé uniquement par le propriétaire du contrat
    //token: adresse du contrat du token ERC20 externe
    //spender: adresse à qui donner la permission de dépenser
    //amount: montant maximal que le spender peut dépenser
    //seul le owner peut appeler (modificateur onlyOwner)
    //L'adresse du token ne doit pas être adresse zéro
    //L'adresse du spender ne doit pas être adresse zéro
    function approveExternalToken(address token, address spender, uint256 amount) public onlyOwner returns (bool) {
        require(token != address(0), "Invalid token address");
        require(spender != address(0), "Invalid spender address");
        
        IERC20(token).approve(spender, amount);
        return true;
    }
}
