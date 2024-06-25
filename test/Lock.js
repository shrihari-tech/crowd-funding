import hardhat from "hardhat";
const { ethers } = hardhat;
import { expect } from "chai";

describe("SimpleCrowdfunding", function () {
  let SimpleCrowdfunding;
  let crowdfunding;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    SimpleCrowdfunding = await ethers.getContractFactory("SimpleCrowdfunding");
    crowdfunding = await SimpleCrowdfunding.deploy();
  });

  it("Should set platform details correctly", async function () {
    await crowdfunding.setPlatformDetails(owner.address, ethers.parseEther("0.01"));
    expect(await crowdfunding.platformOwner()).to.equal(owner.address);
    expect(await crowdfunding.tokenPrice()).to.equal(ethers.parseEther("0.01"));
  });

  it("Should create a new project", async function () {
    await crowdfunding.setPlatformDetails(owner.address, ethers.parseEther("0.01"));
    await crowdfunding.createProject("Project 1", "Description 1", ethers.parseEther("10"), 3600);
    const project = await crowdfunding.projects(0);
    expect(project.name).to.equal("Project 1");
    expect(project.description).to.equal("Description 1");
    expect(project.goal).to.equal(ethers.parseEther("10"));
    expect(project.isActive).to.be.true;
  });

  it("Should allow investment in a project", async function () {
    await crowdfunding.setPlatformDetails(owner.address, ethers.parseEther("0.01"));
    await crowdfunding.createProject("Project 1", "Description 1", ethers.parseEther("10"), 3600);
    
    await crowdfunding.connect(addr1).investInProject(1, { value: ethers.parseEther("1") });
    const project = await crowdfunding.projects(0);
    expect(project.fundsRaised).to.equal(ethers.parseEther("1"));
  });

  it("Should allow project owner to withdraw funds", async function () {
    await crowdfunding.setPlatformDetails(owner.address, ethers.parseEther("0.01"));
    await crowdfunding.createProject("Project 1", "Description 1", ethers.parseEther("10"), 3600);
    
    await crowdfunding.connect(addr1).investInProject(1, { value: ethers.parseEther("1") });

    // Increase time to simulate passing of project duration
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");

    await crowdfunding.connect(owner).withdrawFunds(1);
    const project = await crowdfunding.projects(0);
    expect(project.fundsRaised).to.equal(0);
  });
});
