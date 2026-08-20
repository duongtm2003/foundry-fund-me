-include .env # to load the env variables from the .env file

.PHONY: all test clean deploy fund help install snapshot format anvil zktest
#The .PHONY: tells make that all the names listed after it are not real files 
#and should be treated as commands. Nên nếu không có .phony thì cũng không sao
#nhưng có trường hợp bắt buộc là ví dụ có tên thư mục là test, deploy thì nếu không 
#có .phony nó sẽ báo là đã có file đó rồi nên không chạy câu lệnh được gán
#có hai cách viết: 
#cách 1 dùng :; thì dấu ; biểu thị là viết câu lệnh shell trên cùng 1 dòng
#cách 2 dùng : xuống hàng sau đó bắt buộc phải dùng tab ở đầu dòng

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf example

install :; forge install example

# Update Dependencies
update :; forge update

build :; forge build

test :
	forge test

