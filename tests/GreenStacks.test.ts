import { describe, expect, it, beforeEach } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;

describe("GreenStacks Security Tests", () => {
  beforeEach(() => {
    simnet.mineEmptyBlock();
  });

  describe("Contract Initialization", () => {
    it("ensures simnet is well initialized", () => {
      expect(simnet.blockHeight).toBeDefined();
    });

    it("should have correct initial state", () => {
      const { result: isPaused } = simnet.callReadOnlyFn("GreenStacks", "is-contract-paused", [], deployer);
      expect(isPaused).toBeBool(false);

      const { result: maxMint } = simnet.callReadOnlyFn("GreenStacks", "get-max-mint-per-transaction", [], deployer);
      expect(maxMint).toBeUint(1000000);

      const { result: maxListing } = simnet.callReadOnlyFn("GreenStacks", "get-max-listing-amount", [], deployer);
      expect(maxListing).toBeUint(10000000);

      const { result: totalRetired } = simnet.callReadOnlyFn("GreenStacks", "get-total-retired", [], deployer);
      expect(totalRetired).toBeUint(0);
    });
  });

  describe("Security Functions", () => {
    it("should allow contract owner to pause", () => {
      const { result } = simnet.callPublicFn("GreenStacks", "pause-contract", [], deployer);
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should prevent non-owner from pausing", () => {
      const { result } = simnet.callPublicFn("GreenStacks", "pause-contract", [], address1);
      expect(result).toBeErr(Cl.uint(401));
    });

    it("should allow contract owner to unpause", () => {
      // First pause
      simnet.callPublicFn("GreenStacks", "pause-contract", [], deployer);
      
      // Then unpause
      const { result } = simnet.callPublicFn("GreenStacks", "unpause-contract", [], deployer);
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should allow contract owner to update treasury address", () => {
      const { result } = simnet.callPublicFn("GreenStacks", "set-treasury-address", [Cl.standardPrincipal(address1)], deployer);
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should prevent non-owner from updating treasury address", () => {
      const { result } = simnet.callPublicFn("GreenStacks", "set-treasury-address", [Cl.standardPrincipal(address1)], address2);
      expect(result).toBeErr(Cl.uint(401));
    });

    it("should allow contract owner to update max mint per transaction", () => {
      const { result } = simnet.callPublicFn("GreenStacks", "set-max-mint-per-transaction", [Cl.uint(2000000)], deployer);
      expect(result).toBeOk(Cl.bool(true));
    });

    it("should allow contract owner to update max listing amount", () => {
      const { result } = simnet.callPublicFn("GreenStacks", "set-max-listing-amount", [Cl.uint(20000000)], deployer);
      expect(result).toBeOk(Cl.bool(true));
    });
  });
});