pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "./Table.sol";

contract supply {
    event CreateResult(int256 count);
    event InsertResult(int256 count);
    event UpdateResult(int256 count);
    event RemoveResult(int256 count);

        int from_balance = 0;
        int to_balance = 0;
	string from_address = "";
	string to_address = "";
        string from_type = "";
        string to_type = "";


    function createCompanyTable() public returns(int256) {
        TableFactory tf = TableFactory(0x1001);
        // 企业管理表, key : company, field : item
        // |  企业名称(主键)      |     产品名称       |    企业资产       |
        // |-------------------- |-------------------|------------------|
        // |        company      |       item        |      balance     |
        // |---------------------|-------------------|------------------|
        //
        // 创建表
        int256 count = tf.createTable("haha_t", "company",  "address, type, balance");
        emit CreateResult(count);
        return count;
    }



    /*
    描述 : 资产转移
    参数 ：
            from    : 转移资产企业 
            to      : 接收资产企业
            amount  : 转移金额
    返回值：
            0  注册成功
            -1 其他错误
    */
    function transferBalance(string memory from, string memory to, int amount) public returns(int256) {
        // 查询转移资产账户信息
        int256 ret = 0;

        //打开表
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("haha_t"); 

        (ret, from_address, from_type, from_balance) = selectFromCompany(from);
        (ret, to_address, to_type, to_balance) = selectFromCompany(to);

        Entry entry0 = table.newEntry();
        entry0.set("company", from);
        entry0.set("address", from_address);
        entry0.set("type", from_type);
        entry0.set("balance", int256(from_balance - amount));

        // 更新转账账户
        int count = table.update(from, entry0, table.newCondition());
        if(count != 1) {
            // 失败? 无权限或者其他错误?
            return -1;
        }

        Entry entry1 = table.newEntry();
        entry1.set("company", to);
        entry1.set("address", to_address);
        entry0.set("type", to_type);
        entry1.set("balance", int256(to_balance + amount));

        // 更新接收账户
        count = table.update(to, entry1, table.newCondition());
        if(count != 1){
            // 失败? 无权限或者其他错误?
            return -1;
        }
	    return 0;
    }

    function getResult2(Entries entries) public constant returns(int256, string memory, string memory, int){
        string memory address_ = "";
        string memory type_ = "";
	    int balance = 0;
        if (0 == uint256(entries.size())) { 
            return (-1, address_, type_, balance);
        } else {
            Entry entry = entries.get(0);
            return (0, string(entry.getString("address")), string(entry.getString("type")), int(entry.getInt("balance")));
        }
    } 

    /*
    描述 : 根据企业名称查询产品信息和企业资产
    参数 ：
            company_name : 企业名称

    返回值：
            参数一：成功返回0，企业不存在返回-1
            参数二：第一个参数为0时有效，产品信息
            参数三：第二个参数为0时有效，企业资产
    */
    function selectFromCompany(string company) public constant returns(int256, string memory, string memory, int) {
        // 打开表
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("haha_t");        
        // 查询
        Entries entries = table.select(company, table.newCondition());
        return getResult2(entries);
    }


    /*
    描述 : 企业注册
    参数 ：
            company : 企业名称
            item    : 产品名称
            balance : 企业初始资产
    返回值：
            0  注册成功
            -1 企业已存在
            -2 其他错误
    */
    function register(string memory company, string memory address_, string memory type_, int balance) public returns(int256){
        //int256 ret_code = 0;
        int256 ret= 0;
        string memory temp_address = "";
        string memory temp_type = "";
	    int temp_balance = 0;

        // 查询企业是否存在
        (ret, temp_address, temp_type, temp_balance) = selectFromCompany(company);
        if(ret != 0) {
            //打开表
            TableFactory tf = TableFactory(0x1001);
            Table table = tf.openTable("haha_t"); 

            Entry entry = table.newEntry();
            entry.set("company", company);
            entry.set("address", address_);
            entry.set("type", type_);
	        entry.set("balance", balance);

            // 插入
            int count = table.insert(company, entry);
            if (count == 1) {
                // 成功
                return 0;
            } else {
                // 失败? 无权限或者其他错误
                return -2;
            }
        } else {
            // 企业已存在
            return -1;
        }

    }


    function createReceiptTable() public returns(int256) {
        TableFactory tf = TableFactory(0x1001);
        // 应收账款单据管理表, key : key, field : from, to, amount, due_date, status
        // 创建表
        int256 count = tf.createTable("wow_t", "key",  "from, to, amount, status, due_date");
        emit CreateResult(count);
        return count;
    }
    

    /*
    描述 : 获取表中符合查询条件的记录的相关信息
    参数 ：
            entries : 表中符合条件的记录
    */
    function getResult0(Entries entries) public returns(string[] memory,string[] memory, int[] memory, string[] memory, string[] memory){
        string[] memory from_list = new string[](uint256(entries.size()));
        string[] memory to_list = new string[](uint256(entries.size()));
        int[] memory amount_list = new int[](uint256(entries.size()));
        string[] memory due_date_list = new string[](uint256(entries.size()));
        string[] memory status_list = new string[](uint256(entries.size()));

        for(int i = 0; i < entries.size(); i++){
            Entry entry=entries.get(i);
            from_list[uint256(i)] = entry.getString("from");
            to_list[uint256(i)] = entry.getString("to");
            amount_list[uint256(i)] = entry.getInt("amount");
            due_date_list[uint256(i)] = entry.getString("due_date");
            status_list[uint256(i)] = entry.getString("status");
        }
        return (from_list, to_list, amount_list, status_list, due_date_list);
    }
    

    /*
    描述 : 获取表中符合查询条件的记录的相关信息
    参数 ：
            entries : 表中符合条件的记录
    */
    function getResult1(Entries entries) public constant returns(string[] memory, string[] memory, int[] memory, string[] memory, string[] memory){
        string[] memory from_list = new string[](uint256(entries.size()));
        string[] memory to_list = new string[](uint256(entries.size()));
        int[] memory amount_list = new int[](uint256(entries.size()));
        string[] memory due_date_list = new string[](uint256(entries.size()));
        string[] memory status_list = new string[](uint256(entries.size()));

        for(int i = 0; i < entries.size(); i++){
            Entry entry=entries.get(i);
            from_list[uint256(i)] = entry.getString("from");
            to_list[uint256(i)] = entry.getString("to");
            amount_list[uint256(i)] = entry.getInt("amount");
            due_date_list[uint256(i)] = entry.getString("due_date");
	        status_list[uint256(i)] = entry.getString("status");
        }
        return (from_list,to_list,amount_list,status_list,due_date_list);
    }

    //select records
    function selectFromReceipt(string name, int256 mode) public constant returns(string[] memory,string[] memory,int[] memory,string[] memory, string[] memory) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("wow_t");     

        Condition condition = table.newCondition();
        if(mode == 0){
            condition.EQ("from", name);
        }  
        else if(mode == 1){
            condition.EQ("to", name);
        }
        Entries entries = table.select("active", condition);
	    return getResult0(entries);
    }


    //select records
    function select(string memory from, string memory to) public constant returns(string[] memory,string[] memory,int[] memory,string[] memory,string[] memory) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("wow_t");     

        Condition condition = table.newCondition();

        condition.EQ("from",from);
        condition.EQ("to",to);

        Entries entries = table.select("active", condition);
        return getResult1(entries);
    }


    //insert records
    function insert(string memory from, string memory to, int amount, string memory due_date, string memory status) public returns (int256){
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("wow_t");

        Entry entry = table.newEntry();
        entry.set("key", "active");
        entry.set("from", from);
        entry.set("to", to);
        entry.set("amount", amount);
        entry.set("due_date", due_date);
	    entry.set("status",status);

        int256 count = table.insert("active", entry);
        emit InsertResult(count);

        return count;
    }


    //update records
    function update(string memory from, string memory to, int amount, string memory status, string memory due_date)
    public
    returns (int256)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("wow_t");

        Entry entry = table.newEntry();
        entry.set("amount", amount);
        entry.set("due_date", due_date);
	    entry.set("status", status);

        Condition condition = table.newCondition();
        condition.EQ("from", from);
        condition.EQ("to", to);

        int256 count = table.update("active", entry, condition);
        emit UpdateResult(count);

        return count;
    }


    //remove records
    function remove(string memory from, string memory to, int amount, string memory due_date) public returns (int256) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("wow_t");

        Condition condition = table.newCondition();
        condition.EQ("from", from);
        condition.EQ("to", to);
        condition.EQ("amount", amount);
        condition.EQ("due_date", due_date);

        int256 count = table.remove("active", condition);
        emit RemoveResult(count);

        return count;
    }


    /*
    描述 : 采购商品，签发应收账款
    参数 ：
            from    : 付款企业名称
            to      : 收款企业名称
            amount  : 账款金额
            due_date：还款日期
    返回值：
            0  采购成功
            -1 付款企业不存在
            -2 收款企业不存在
            -3 其他错误
    */
    function purchase(string memory from, string memory to, int amount, string memory due_date) public returns(int256) {
        int256 ret = 0;
        string memory temp_address = "";
        string memory temp_type = "";
	    int balance = 0;

        (ret, temp_address, temp_type, balance) = selectFromCompany(to);
        if(ret!=0){
            return -2;
        }

	    (ret, temp_address, temp_type, balance) = selectFromCompany(from);
        if(ret!=0){
            return -1;
        }
	
	if(balance>>1 >= amount){
	    ret = transferBalance(from, to, amount);
	    if(ret==0){
		    return 0;
	    }
	    else{
		    return -3;
	    }
	}
	else{
            int256 count = insert(from,to,amount,due_date,"identified");
            if(count==1){
                return 0;
            }
            else{
                return -3;
            }
        }
    }

    /*
    描述 : 转让应收账款
    参数 ：
            from    : 付款企业名称
            to      : 收款企业名称
            third   : 第三方企业名称
            amount  : 账款金额
    返回值：
            0  采购成功
            -1 付款企业不存在
            -2 收款企业不存在
            -3 第三方企业不存在
            -4 转让金额超过付款企业和收款企业之间的应收账款金额
            -5 转让金额超过收款企业和第三方企业之间的应收账款金额
    */
    function transfer(string memory from, string memory to, string memory third, int amount) public returns(int256){
        int256 ret = 0;
        string memory temp_address = "";
        string memory temp_type = "";
	    int balance = 0;
        string[] memory from_list;
        string[] memory to_list;
        string[] memory due_date_list;
        int[] memory amount_list;
	    string[] memory status_list;

        (ret, temp_address, temp_type, balance) = selectFromCompany(from);
        if(ret!=0){
            return -1;
        }
        (ret, temp_address, temp_type, balance) = selectFromCompany(to);
        if(ret!=0){
            return -2;
        }
        (ret, temp_address, temp_type, balance) = selectFromCompany(third);
        if(ret!=0){
            return -3;
        }

        (from_list,to_list,amount_list,due_date_list,status_list) = select(from, to);
        if(amount_list[uint256(0)] < amount){
            return -4;
        }
        update(from, to, amount_list[uint256(0)]-amount, status_list[uint256(0)], due_date_list[uint256(0)]);
        insert(from, third, amount, due_date_list[uint256(0)], "identified");

        (from_list, to_list, amount_list, due_date_list,status_list) = select(to, third);
        if(amount_list[uint256(0)] < amount){
            return -5;
        }
        update(to, third, amount_list[uint256(0)]-amount, status_list[uint256(0)], due_date_list[uint256(0)]);
        return 0;
    }
    

    /*
    描述 : 清算应收账款，支付欠款
    参数 ：
            from    : 付款企业名称
            to      : 收款企业名称
            amount  : 账款金额
            due_date: 还款日期
    返回值：
            0  清算成功
            -1 其他错误
    */
    function repay(string memory from, string memory to, int amount, string memory due_date) public returns(int256){
        int256 ret_code = 0;
	    int256 ret = transferBalance(from, to, amount);
        int256 count = remove(from, to, amount, due_date);
        if(count == 1 && ret == 0){
            ret_code = 0;
        }
        else{
            ret_code = -1;
        }
        return ret_code;
    }


    /*
    描述 : 向银行申请融资
    参数 ：
            to      : 申请融资企业名称
            amount  : 账款金额
            due_date: 还款日期
    返回值：
            0  融资成功
            -1 其他错误
    */
    function finance(string memory to, int256 amount, string memory due_date) public returns(int256){
        int256 count = insert(to,"bank",amount,due_date,"identified");
	    int ret = transferBalance("bank",to,amount);
	    if(count==1 && ret==0){
	        return 0;
	    }
	    else{
	        return -1;
	    }
    }

}
