pragma solidity ^0.4.0;
contract Bank{
    address owner;
    bytes32 public bankName;
    bytes32 public bankID;

    //address[] applicantConAddrs;
    address[] individualConAddrs;
    address[] cashedDraftAddrs;
    address[] draftOperations;

    function Bank(bytes32 _bankName,bytes32 _bankID){
        owner=msg.sender;
        bankName = _bankName;
        bankID = _bankID;
    }
}

contract Individual {
    address owner;
    bytes32 id;
    bytes32 companyName;
    bytes32 userName;
    bytes32 phoneNum;
    bytes32 idNum;
 
    address[] issueOperationAddrs; //出票操作合约地址
    address[] signedOperationAddrs; //签收操作合约地址
    address[] transferOperationAddrs; //转让操作合约地址
    
    address applicantConAddr;

    DraftInfo draftInfo;

    function Individual(address _individualAddr,bytes32 _id,bytes32 _companyName,bytes32 _phoneNum,bytes32 _userName,bytes32 _idNum){
        owner = _individualAddr;
        id=_id;
        companyName=_companyName;
        userName=_userName;
        phoneNum=_phoneNum;
        idNum=_idNum;
    }

    struct DraftInfo{
        address  applicantConAddr;
        address operatorConAddr;
        bytes32 draftNum;
        Draft.SignType signType;
        uint16 currencyType;
        uint faceValue;
        uint signTime;
        uint cashTime;
        uint validDays;
        uint frozenDays;
        uint autoCashDays;
    }

    // 出票成功
    function issueSuccess(address draftAddr,address toAppConAddr,bytes32 sequenceNum,address fromConAddr,address toConAddr,uint operationTime) returns(address){
        Draft draft=Draft(draftAddr);
        uint value=draft.getFaceValue();
        DraftOperation draftOperation=new DraftOperation(sequenceNum,fromConAddr,0x0,toConAddr,0x0,draftAddr,draftAddr,value,operationTime,DraftOperation.OperationType.Issue);

        draft.setState(Draft.DraftState.Signed);
        draft.changeOwner(toAppConAddr,toConAddr);

        issueOperationAddrs.push(draftOperation);
        return draftOperation;
    }
 
    // 兑付汇票成功
    function cashSuccess(address draftAddr,address newDraftAddr,address _bankConAddr,address draftOperationAddr) {
        Draft newDraft=Draft(newDraftAddr);
        newDraft.changeOwner(_bankConAddr,_bankConAddr);
        newDraft.setState(Draft.DraftState.Cashed);

        DraftOperation draftOperation = DraftOperation(draftOperationAddr);
        copyOperationAddr(draftAddr,newDraftAddr,draftOperation);
    }
    
    // 产生新汇票时将父汇票的所有历史记录复制进新汇票
    function copyOperationAddr(address draftAddr,address newDraftAddr,address operation){
        Draft oldDraft=Draft(draftAddr);
        Draft newDraft=Draft(newDraftAddr);
        uint length=oldDraft.getOperationsLen();
        for(uint i=0;i<length;i++){
           address temp=oldDraft.getOperationAddr(i);          
        }
    }
}
contract Draft{
    enum SignType{PayAtSight,PayAtFixedDate} //票据类型包括见票即付型和定日付款型两种
    SignType signType;
    enum DraftState{Saved,UnIssue,IssueNotSigned,Issuing,Signed,TransferNotSigned,Cashing,Cashed,Invalid}//票据状态枚举
    DraftState public draftState;
    bytes32 draftNum; //票据编号
    bytes32 public acceptBankName; //承兑行名称
    bytes32 public acceptBankNum; //承兑行行别
    address applicantConAddr; //申请人合约地址
    address operatorConAddr; //经办人合约地址
    uint16 currencyType; //票据币种
    uint faceValue; //票据面额
    uint signTime; //签发时间
    uint signedTime; //签收时间
    uint cashTime; //兑付时间
    uint validDays; //有效期
    uint frozenDays; //冻结期
    address[] draftOperationAddrs; //票据操作合约地址数组

    function Draft(bytes32 _draftNum,SignType _signType,DraftState _draftState,uint _validDays,uint _frozenDays,uint _autoCashedDays,uint _signTime,uint _faceValue,address _applicanConAddr,address _operatorConAddr,uint16 _currencyType){
        draftNum=_draftNum;
        signType=_signType;
        draftState=_draftState;
        validDays=_validDays;
        frozenDays=_frozenDays;
        //autoCashDays= _autoCashedDays;
        signTime=_signTime;
        faceValue=_faceValue;
        applicantConAddr=_applicanConAddr;
        operatorConAddr=_operatorConAddr;
        currencyType=_currencyType;
    }

    function getOperationAddr(uint i) constant returns(address){
        return draftOperationAddrs[i];
    }
    function getOperationsLen() constant returns(uint){
        return draftOperationAddrs.length;
    }  
    function getFaceValue() constant returns(uint){
        return faceValue;
    }
    function setState(DraftState _state) {
        draftState=_state;
    }    
    
    // 改变合约拥有者
    function changeOwner(address _applicantConAddr,address _operatorConAddr){
        applicantConAddr=_applicantConAddr;
        operatorConAddr=_operatorConAddr;
    }

}
contract DraftOperation{
    bytes32 public sequenceNum; //操作流水号
    address public fromConAddr; //交易上家合约地址
    bytes32 public fromId; //交易上家
    address public toConAddr; //交易下家合约地址
    bytes32 public toId; //交易下家
    address public draftAddr; //原票据地址
    address public newDraftAddr; //新票据地址
    uint public value; //金额
    uint public operation1Time;
    uint public operationTime; //操作时间
    enum OperationType{Sign,Issue,Transfer,Cash}  //交易类型
    OperationType public operationType;
    enum TxState{Success,ToSignature,ToCharge,SignatureFail,ChargeFail} //交易结果
    TxState public txState = TxState.ToSignature;

    function DraftOperation(bytes32 _sequenceNum,address _fromConAddr,bytes32 _fromId,address _toConAddr,bytes32 _toId,address _draftAddr,address _newDraftAddr,uint _value,uint _operation1Time,OperationType _operationType){
        sequenceNum=_sequenceNum;
        fromConAddr=_fromConAddr;
        fromId=_fromId;
        toConAddr=_toConAddr;
        toId=_toId;
        draftAddr=_draftAddr;
        newDraftAddr=_newDraftAddr;
        value=_value;
        operation1Time=_operation1Time;
        operationType=_operationType;
    }
 
}

