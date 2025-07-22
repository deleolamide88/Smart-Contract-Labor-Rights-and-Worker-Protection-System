# Smart Contract Labor Rights and Worker Protection System

A comprehensive blockchain-based system designed to protect workers' rights and prevent labor exploitation through automated smart contracts.

## System Overview

This system consists of five interconnected smart contracts that address critical labor rights issues:

### 1. Wage Theft Prevention Contract (`wage-theft-prevention.clar`)
- **Purpose**: Ensures workers receive full compensation for hours worked
- **Features**:
    - Automated wage calculations based on logged hours
    - Escrow system for wage protection
    - Penalty mechanisms for late payments
    - Dispute resolution system

### 2. Workplace Safety Monitoring Contract (`workplace-safety-monitoring.clar`)
- **Purpose**: Tracks occupational hazards and safety violations
- **Features**:
    - Safety incident reporting system
    - Hazard level tracking
    - Compliance monitoring
    - Safety score calculations

### 3. Union Organizing Protection Contract (`union-organizing-protection.clar`)
- **Purpose**: Protects workers' rights to organize and bargain collectively
- **Features**:
    - Anonymous union membership tracking
    - Protection against retaliation
    - Collective bargaining agreement management
    - Voting mechanisms for union decisions

### 4. Gig Worker Classification Contract (`gig-worker-classification.clar`)
- **Purpose**: Ensures proper classification and benefits for gig economy workers
- **Features**:
    - Worker classification determination
    - Benefits eligibility tracking
    - Hours and earnings monitoring
    - Misclassification penalties

### 5. Cross-Border Labor Rights Contract (`cross-border-labor-rights.clar`)
- **Purpose**: Protects migrant workers from exploitation and abuse
- **Features**:
    - Work permit and visa status tracking
    - Fair wage enforcement across borders
    - Protection against document confiscation
    - Repatriation assistance fund

## Key Features

### Automated Protection
- Smart contracts automatically enforce labor protections
- Real-time monitoring of compliance
- Immediate response to violations

### Transparency
- All labor data recorded on blockchain
- Immutable record of working conditions
- Public access to anonymized statistics

### Worker Empowerment
- Direct access to protection mechanisms
- Anonymous reporting capabilities
- Collective action coordination

### Employer Accountability
- Automatic penalty enforcement
- Reputation system based on compliance
- Incentives for good labor practices

## Technical Architecture

### Data Types
- **Worker**: Principal address, employment status, hours worked
- **Employer**: Principal address, compliance score, active contracts
- **Work Record**: Hours, wages, safety incidents, classifications
- **Union**: Membership count, collective agreements, voting records

### Error Handling
- Comprehensive error codes for all failure scenarios
- Clear error messages for debugging
- Graceful handling of edge cases

### Security Features
- Principal-based access control
- Input validation on all functions
- Protection against common attack vectors

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation
\`\`\`bash
git clone <repository-url>
cd labor-rights-system
npm install
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### For Workers
1. **Register as Worker**: Call `register-worker` function
2. **Log Work Hours**: Use `log-work-hours` to record time worked
3. **Report Safety Issues**: Call `report-safety-incident` for hazards
4. **Join Union**: Use `join-union` for collective protection

### For Employers
1. **Register as Employer**: Call `register-employer` function
2. **Create Work Contracts**: Use `create-work-contract` for agreements
3. **Process Payments**: Call `process-wage-payment` for compensation
4. **Update Safety Records**: Use safety monitoring functions

### For Unions
1. **Create Union**: Call `create-union` function
2. **Manage Members**: Use membership management functions
3. **Negotiate Agreements**: Utilize collective bargaining features
4. **Coordinate Actions**: Use voting and decision-making tools

## Contract Interactions

Each contract operates independently but shares common data structures for interoperability:

- **Worker Registry**: Shared across all contracts
- **Employer Registry**: Common employer tracking
- **Compliance Scores**: Unified reputation system
- **Event Logging**: Consistent audit trail

## Compliance and Legal

This system is designed to support compliance with:
- International Labour Organization (ILO) standards
- National labor laws and regulations
- Industry-specific safety requirements
- Cross-border employment agreements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write comprehensive tests
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Review the documentation wiki
