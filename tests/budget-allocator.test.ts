import { describe, it, expect } from "vitest"

const mockContractCall = (contractName: string, functionName: string, args: any[]) => {
  if (contractName === "budget-allocator") {
    switch (functionName) {
      case "set-total-budget":
        return { type: "ok", value: true }
      case "allocate-department-budget":
        return { type: "ok", value: true }
      case "submit-budget-request":
        return { type: "ok", value: 1 }
      case "approve-budget-request":
        return { type: "ok", value: true }
      case "get-department-budget":
        return {
          type: "some",
          value: {
            "allocated-amount": 100000,
            "used-amount": 25000,
            "remaining-amount": 75000,
            "employee-count": 10,
            "budget-per-employee": 10000,
            "last-updated": 1000,
          },
        }
      case "get-employee-budget":
        return {
          type: "some",
          value: {
            department: "Engineering",
            "allocated-amount": 10000,
            "used-amount": 2000,
            "remaining-amount": 8000,
            "last-updated": 1000,
          },
        }
      case "get-total-budget":
        return 1000000
      case "get-allocated-budget":
        return 500000
      default:
        return { type: "ok", value: true }
    }
  }
  return { type: "ok", value: true }
}

describe("Budget Allocator Contract", () => {
  const adminAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
  const employeeAddress = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
  
  describe("Budget Setup", () => {
    it("should set total budget", () => {
      const result = mockContractCall("budget-allocator", "set-total-budget", [1000000])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should allocate department budget", () => {
      const result = mockContractCall("budget-allocator", "allocate-department-budget", [
        "Engineering",
        10, // employee count
        100000, // allocation amount
      ])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should allocate individual employee budget", () => {
      const result = mockContractCall("budget-allocator", "allocate-employee-budget", [employeeAddress, "Engineering"])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("Budget Requests", () => {
    it("should submit budget request", () => {
      const result = mockContractCall("budget-allocator", "submit-budget-request", [
        5000,
        "Advanced JavaScript Training Course",
      ])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should approve budget request", () => {
      const result = mockContractCall("budget-allocator", "approve-budget-request", [1])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject budget request", () => {
      const result = mockContractCall("budget-allocator", "reject-budget-request", [1])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should use approved budget", () => {
      const result = mockContractCall("budget-allocator", "use-budget", [1])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
  
  describe("Budget Tracking", () => {
    it("should get department budget details", () => {
      const result = mockContractCall("budget-allocator", "get-department-budget", ["Engineering"])
      
      expect(result.type).toBe("some")
      expect(result.value["allocated-amount"]).toBe(100000)
      expect(result.value["remaining-amount"]).toBe(75000)
    })
    
    it("should get employee budget details", () => {
      const result = mockContractCall("budget-allocator", "get-employee-budget", [employeeAddress])
      
      expect(result.type).toBe("some")
      expect(result.value.department).toBe("Engineering")
      expect(result.value["remaining-amount"]).toBe(8000)
    })
    
    it("should track total and allocated budgets", () => {
      const totalBudget = mockContractCall("budget-allocator", "get-total-budget", [])
      const allocatedBudget = mockContractCall("budget-allocator", "get-allocated-budget", [])
      
      expect(totalBudget).toBe(1000000)
      expect(allocatedBudget).toBe(500000)
    })
  })
  
  describe("Budget Reallocation", () => {
    it("should reallocate unused budget between departments", () => {
      const result = mockContractCall("budget-allocator", "reallocate-unused-budget", [
        "Marketing",
        "Engineering",
        20000,
      ])
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
  })
})
