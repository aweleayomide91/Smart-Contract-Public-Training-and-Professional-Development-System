# Smart Contract Public Training and Professional Development System

## Overview

This system provides a comprehensive blockchain-based solution for managing employee training programs, certifications, budget allocation, skills assessment, and training effectiveness evaluation. Built on the Stacks blockchain using Clarity smart contracts.

## System Architecture

### Core Contracts

1. **Training Program Management (`training-program.clar`)**
    - Manages mandatory and professional development training programs
    - Tracks program enrollment and completion
    - Handles program scheduling and capacity management

2. **Certification Tracking (`certification-tracker.clar`)**
    - Maintains employee certification records
    - Manages certification renewals and expiration tracking
    - Validates certification requirements

3. **Training Budget Allocation (`budget-allocator.clar`)**
    - Distributes training funds across departments and employees
    - Tracks budget utilization and remaining balances
    - Manages budget approval workflows

4. **Skills Assessment (`skills-assessment.clar`)**
    - Identifies training needs through skills gap analysis
    - Tracks career development opportunities
    - Manages competency frameworks

5. **Training Effectiveness Evaluation (`training-evaluator.clar`)**
    - Measures training program impact on job performance
    - Collects and analyzes training feedback
    - Generates effectiveness reports

## Key Features

- **Decentralized Training Management**: All training records stored on blockchain
- **Automated Certification Tracking**: Smart contract-based renewal reminders
- **Fair Budget Distribution**: Algorithmic budget allocation across departments
- **Skills Gap Analysis**: Data-driven identification of training needs
- **Performance Impact Measurement**: Quantifiable training effectiveness metrics

## Data Structures

### Employee Profile
- Employee ID (principal)
- Department
- Role/Position
- Skill levels
- Training history
- Certification status

### Training Program
- Program ID
- Program type (mandatory/professional)
- Duration
- Capacity
- Prerequisites
- Completion criteria

### Certification
- Certification ID
- Certification name
- Expiration date
- Renewal requirements
- Issuing authority

### Budget Allocation
- Department ID
- Allocated amount
- Used amount
- Remaining balance
- Approval status

## Security Features

- Role-based access control (admin, manager, employee)
- Input validation and error handling
- Immutable training records
- Transparent budget tracking

## Getting Started

1. Deploy contracts to Stacks testnet/mainnet
2. Initialize system with admin principal
3. Set up departments and roles
4. Configure training programs
5. Allocate initial budgets

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

## Contract Interactions

### For Administrators
- Add/remove training programs
- Allocate budgets
- Generate reports
- Manage certifications

### For Managers
- Enroll employees in training
- Approve budget requests
- View department analytics
- Conduct skills assessments

### For Employees
- View available training programs
- Track certification status
- Submit training feedback
- Access personal development plans
