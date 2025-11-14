// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//on donne un nom de contrat ERC20 (norme)
//dans ce cas NeverGoon
contract NeverGoon {
    using SafeERC20 for IERC20;

    //informations générales du token
    string public name = "NeverGoon";
    string public symbol = "GOON";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    //stocke le solde de chaque adresse
    mapping(address => uint256) public balanceOf;
    //stocke les autorisations d'allocations de tokens pour chaque adresse
    mapping(address => mapping(address => uint256)) public allowance;
    
    //adresse du propriétaire du contrat
    address public owner;
    
    //événements émis lors du transfert, approbations et brûlages
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    //on initialise le nombre de token total (dans ce cas : illimité)
    //le déployeur est crédité car déployé un contrat coûte de l'argent (dépend de la blockchain)
    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    //permet de transférer des tokens vers une autre adresse
    //N'importe quel utilisateur possédant des tokens
    //to = adresse du destinataire
    //value = nombre de token à transférer
    //l'adresse ne peut pas être null, l'envoyeur doit avoir un solde > 0
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= value, "Insufficient tokens");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    //permet de transférer des tokens d'une adresse à une autre avec l'autorisations préalable
    //appelé par un tiers autorisé à dépenser les tokens d'une autres personnes
    //from = adresse source (celui qui possède les tokens)
    //to = adresse du destinataire
    //value = le nombre de token que l'on veut transférer
    //l'adresse du destinataire ne peut pas être null
    //l'adresse source doit avoir plus que > 0 tokens
    //Une autorisation préalable doit avoir été donnée (la fonction approve)
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient tokens in source account");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }

    //permet d'approuver un tiers à dépenser des token en votre nom
    //spender : adresse autorisée à dépenser les tokens d'une autre personne
    //value : montant maximal que le spender peut dépenser sur le solde d'une autre personne
    //l'adresse du spender ne peut pas être null
    //La personne doit être propriétaire de ses propres tokens
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        _approve(msg.sender, spender, value);
        return true;
    }

    //fonctions interne pour approuver les allocations de tokens
    //utilisé dans les fonctions approve(), increaseAllowance(), decreaseAllowance()
    //_owner : propriétaire des tokens
    //spender : adresse autorisé à utilise des tokens qui ne sont pas les siens
    //value : montant autorisé à être utilisé
    function _approve(address _owner, address spender, uint256 value) internal {
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    //augmente l'allocation pour un tiers
    //peut être appelé par un propriétaire de token
    //augmente le montant maximal utilisable par un tiers sur le compte d'une autre personne
    //spender : adresse dont on augmente l'allocation
    //addedValue : montant à ajouter à l'allocation déjà existante
    //L'adresse spender ne peut pas être null
    //Le montant addedValue doit être supérieur à 0
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        require(addedValue > 0, "Added value must be greater than 0");
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    //diminue l'allocation autorisée pour un tiers
    //peut être appelé par un propriétaire de token
    //spender : adresse où on diminue l'allocation
    //subtractedValue : montant à soustraire à l'allocation déjà existante
    //L'adresse du spender ne peur pas être null
    //Le montant subtractedValue doit être supérieur à 0
    //Le montant subtractedValue ne peut pas être supérieur à l'allocation déjà existante
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        require(subtractedValue > 0, "Subtracted value must be greater than 0");
        require(allowance[msg.sender][spender] >= subtractedValue, "Allowance too low");
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    //permet de brûler ses propres tokens
    //peut être appelé par n'importe quel propriétaire de token
    //value : nombre de token que l'on veut brûler (détruire en gros)
    //l'appellant doit avoir au moins des tokens
    //l'appellant doit avoir assez d'allocation pour brûler les tokens
    //ça réduit le totalSupply du contrat (token en circulation)
    //réduit le solde de l'utilisateur
    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient tokens to burn");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    //permet de brûler les tokens d'une autre adresse avec autorisation préalable
    //from : adresse dont on veut brûler des tokens
    //value : nombre de token que l'on veut brûler
    //l'adresse from doit avoir des tokens en stocks
    //l'appelant doit avoir une allocation suffisante (allowance >= value)
    //Une autorisation doit être fourni au préalable
    function burnFrom(address from, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient tokens to burn");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        
        balanceOf[from] -= value;
        totalSupply -= value;
        allowance[from][msg.sender] -= value;
        
        emit Burn(from, value);
        emit Transfer(from, address(0), value);
        return true;
    }

    //permet au propriétaires de créer de nouveaux tokens (c'est le minage)
    //peut être appelé uniquement par le propriétaire du contrat
    //value : nomnbre de tokens à créer
    //value doit être supérieur à 0
    function mint(uint256 value) public onlyOwner returns (bool) {
        totalSupply += value;
        balanceOf[owner] += value;
        emit Transfer(address(0), owner, value);
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
     //pender: adresse à qui donner la permission de dépenser
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
