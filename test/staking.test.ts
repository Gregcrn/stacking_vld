import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer, BigNumber } from "ethers";
import { Event } from "@ethersproject/contracts";


const { provider } = ethers;

describe("Staking", () => {
    let Staking: Contract;
    let owner: Signer;
    let addr1: Signer;
    let addr2: Signer;
    let addrs: Signer[];

    beforeEach(async () => {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        const StakingFactory = await ethers.getContractFactory("Staking");
        Staking = await StakingFactory.deploy();
        await Staking.deployed();
    });

    describe("stake()", () => {
        it("should successfully stake and emit Staked event", async () => {
            const addr1Address = await addr1.getAddress();
            const stakeAmount = ethers.utils.parseEther("1");
            const stakeDurationIndex = 0;

            await expect(
                Staking.connect(addr1).stake(stakeDurationIndex, { value: stakeAmount })
            )
                .to.emit(Staking, "Staked")
                .withArgs(addr1Address, stakeAmount, 30 * 24 * 60 * 60, 20);

            const addr1Balance = await Staking.balanceOf(addr1Address);
            expect(addr1Balance).to.equal(stakeAmount);

            const addr1Stakes = await Staking.getStakes(addr1Address);
            expect(addr1Stakes.length).to.equal(1);
            expect(addr1Stakes[0].amount).to.equal(stakeAmount);
        });
    });

    describe("unstake()", () => {
        it("should successfully unstake an expired stake and emit Unstaked event", async () => {
            const addr1Address = await addr1.getAddress();
            const stakeAmount = ethers.utils.parseEther("1");
            const stakeDurationIndex = 0;

            // Stake for 30 days
            await Staking.connect(addr1).stake(stakeDurationIndex, { value: stakeAmount });

            const addr1Stakes = await Staking.getStakes(addr1Address);
            const stakeId = addr1Stakes[0].id;

            // Fast forward 30 days
            await provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);

            // Unstake expired stake
            await expect(Staking.connect(addr1).unstake(stakeId))
                .to.emit(Staking, "Unstaked")
                .withArgs(addr1Address, stakeAmount);


            const addr1Balance = await Staking.balanceOf(addr1Address);
            expect(addr1Balance).to.equal(0);

            const addr1Earnings = await Staking.earningsOf(addr1Address);
            expect(addr1Earnings).to.equal(stakeAmount.mul(20).mul(30).div(365));
        });

    });

});
