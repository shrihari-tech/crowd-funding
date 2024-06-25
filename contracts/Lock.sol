// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleCrowdfunding {
    // Structure to hold project details
    struct Project {
        uint256 id;
        string name;
        string description;
        address payable owner;
        uint256 goal;
        uint256 deadline;
        uint256 fundsRaised;
        bool isActive;
    }

    // Arrays to store projects
    Project[] public projects;

    // Token details
    string public tokenName = "EquityToken";
    string public tokenSymbol = "EQT";
    uint8 public tokenDecimals = 18;
    uint256 public totalTokens;
    uint256 public tokenPrice; // in wei

    // Address of the platform owner
    address public platformOwner;

    // Modifier to restrict access to only the platform owner
    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can perform this action");
        _;
    }

    // Events to log project creation and investment
    event ProjectCreated(uint256 id, string name, string description, address owner, uint256 goal, uint256 deadline);
    event InvestmentMade(uint256 projectId, address investor, uint256 amount, uint256 tokensIssued);

    // Function to set the platform owner and token price (only callable once)
    function setPlatformDetails(address _platformOwner, uint256 _tokenPrice) public {
        require(platformOwner == address(0), "Platform details already set");
        platformOwner = _platformOwner;
        tokenPrice = _tokenPrice;
    }

    // Function to create a new project
    function createProject(string memory _name, string memory _description, uint256 _goal, uint256 _duration) public {
        uint256 projectId = projects.length + 1;
        Project memory newProject = Project({
            id: projectId,
            name: _name,
            description: _description,
            owner: payable(msg.sender),
            goal: _goal,
            deadline: block.timestamp + _duration,
            fundsRaised: 0,
            isActive: true
        });
        projects.push(newProject);
        emit ProjectCreated(projectId, _name, _description, msg.sender, _goal, newProject.deadline);
    }

    // Function to invest in a project
    // Function to invest in a project
function investInProject(uint256 _projectId) public payable {
    require(_projectId > 0 && _projectId <= projects.length, "Project does not exist");
    Project storage project = projects[_projectId - 1];
    require(project.isActive, "Project is not active");
    require(block.timestamp < project.deadline, "Project funding period has ended");
    require(msg.value > 0, "Investment amount should be greater than 0");

    uint256 tokensToIssue = msg.value / tokenPrice;
    totalTokens += tokensToIssue;
    project.fundsRaised += msg.value;

    emit InvestmentMade(_projectId, msg.sender, msg.value, tokensToIssue);

    if (project.fundsRaised >= project.goal) {
        project.isActive = false;
    }
}

// Function to withdraw funds from a project
function withdrawFunds(uint256 _projectId) public {
    require(_projectId > 0 && _projectId <= projects.length, "Project does not exist");
    Project storage project = projects[_projectId - 1];
    require(!project.isActive || block.timestamp >= project.deadline, "Project is still active");
    require(project.owner == msg.sender, "Only project owner can withdraw funds");
    require(project.fundsRaised > 0, "No funds to withdraw");

    uint256 amount = project.fundsRaised;
    project.fundsRaised = 0;
    project.owner.transfer(amount);
}


    // Function to get all projects
    function getAllProjects() public view returns (Project[] memory) {
        return projects;
    }

    // Fallback function to prevent accidental ETH transfer
    receive() external payable {
        revert("Direct ETH transfer not allowed");
    }
}
