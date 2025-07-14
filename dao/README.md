# Scholarship DAO - Enhanced Version 2.0

A decentralized autonomous organization (DAO) built on Stacks blockchain for managing scholarship funds with enhanced security, governance, and functionality.

## Overview

The Scholarship DAO allows members to propose scholarship recipients, vote on proposals, and automatically disburse funds when proposals meet the required threshold. Version 2.0 includes significant security improvements, bug fixes, and new governance features.

## Features

### Core Functionality
- **Proposal System**: Members can submit scholarship proposals with descriptions, amounts, and recipients
- **Voting Mechanism**: Members vote on proposals with anti-double-voting protection
- **Automatic Disbursement**: Admin can approve and disburse funds when vote threshold is met
- **Time-based Proposals**: Proposals now have deadlines to prevent stale proposals

### Security Enhancements
- **Membership System**: Only registered members can submit proposals and vote
- **Balance Tracking**: Contract tracks its own balance to prevent over-disbursement
- **Vote Verification**: Prevents double voting with dedicated vote tracking
- **Access Control**: Enhanced admin controls with proper authorization checks

### Governance Features
- **Admin Change Proposals**: Democratic process for changing admin
- **Authorized Voters**: Separate governance voting system
- **Parameter Updates**: Vote threshold can be adjusted by admin
- **Proposal History**: Complete audit trail of all proposals and votes

## Smart Contracts

### 1. `scholarship-dao.clar`
Main contract handling scholarship proposals, voting, and disbursement.

**Key Functions:**
- `submit-proposal`: Create new scholarship proposals
- `vote`: Vote on existing proposals
- `approve-and-disburse`: Admin function to execute approved proposals
- `add-member`: Admin function to add new members
- `deposit-funds`: Fund the scholarship pool

### 2. `governance.clar`
Governance contract for democratic administration changes.

**Key Functions:**
- `propose-admin-change`: Propose new admin
- `vote-governance`: Vote on governance proposals  
- `execute-governance-proposal`: Execute approved governance changes
- `add-authorized-voter`: Add governance participants

## Bug Fixes from Version 1.0

1. **Double Voting Prevention**: Added vote tracking to prevent users from voting multiple times
2. **Proposal Expiration**: Added deadline system to prevent indefinite proposals
3. **Balance Validation**: Contract now tracks balance to prevent over-disbursement
4. **Input Validation**: Added checks for valid amounts and parameters
5. **Access Control**: Proper membership and authorization checks

## Usage

### For Members
1. **Join the DAO**: Admin must add you as a member
2. **Submit Proposals**: Use `submit-proposal` with description, amount, recipient, and duration
3. **Vote**: Use `vote` function with proposal ID
4. **Track Progress**: Use read-only functions to monitor proposal status

### For Admins
1. **Add Members**: Use `add-member` to expand the DAO
2. **Set Parameters**: Adjust vote thresholds as needed
3. **Approve Proposals**: Use `approve-and-disburse` for successful proposals
4. **Fund Contract**: Use `deposit-funds` to add scholarship money

### For Governance
1. **Propose Changes**: Use governance contract to propose admin changes
2. **Vote on Changes**: Participate in governance votes
3. **Execute Changes**: Implement approved governance proposals

## Testing

Run the test suite using Clarinet:

```bash
clarinet test
```

## Deployment

1. **Local Development**:
   ```bash
   clarinet console
   ```

2. **Testnet Deployment**:
   ```bash
   clarinet deploy --testnet
   ```

3. **Mainnet Deployment**:
   ```bash
   clarinet deploy --mainnet
   ```

## Configuration

The `Clarinet.toml` file includes:
- Contract definitions for both scholarship and governance contracts
- Test accounts with pre-funded balances
- Network configurations for testnet and mainnet
- Development settings for local testing

## Security Considerations

- **Admin Keys**: Keep admin private keys secure
- **Member Vetting**: Carefully vet members before adding them
- **Proposal Review**: Review proposals thoroughly before voting
- **Balance Monitoring**: Regularly check contract balance
- **Governance Participation**: Actively participate in governance votes

## Error Codes

- `u100`: Not admin
- `u101`: Invalid proposal ID
- `u102`: Already approved
- `u103`: Not a member
- `u104`: Already voted
- `u105`: Insufficient funds
- `u106`: Proposal expired
- `u107`: Invalid amount
- `u108`: Invalid threshold
- `u200-u206`: Governance-related errors

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Version History

- **v2.0.0**: Enhanced security, governance features, bug fixes
- **v1.0.0**: Initial implementation with basic DAO functionality

## Future Enhancements

- Multi-signature wallet integration
- Automated compliance checks
- Advanced voting mechanisms (quadratic voting)
- Integration with educational institutions
- Mobile app interface
- Analytics dashboard
