# Replication Package: [Longitudinal-Hearing-Aid-Benefits]

This folder contains the code and instructions to replicate the findings of "Longitudinal Growth of Mandated Hearing Aid Benefits in the US" published in JAMA-Otolaryngology.

## Data Availability Statement
- **Raw Data:** Data is public access, available via the Agency for Healthcare Research and Quality (AHRQ), IPUMS USA, and the Social Impact Lab.
- 
- **Data Access:** SIL Healthcare Policy Data available at: https://social-impact-lab-sil.github.io/SIL-Data-Repository/Hearing-Healthcare-Policy/
- **Note:** If using restricted data, the scripts provided here assume you have placed the raw files in the `/data` folder.

## Software Requirements
- **Primary Software:** STATA18
- **Required Packages/Libraries:** - No additional package requirements

## Instructions
1. **Set Directory:** Open the do file and update directory information. 
2. **Run Analysis:** All analysis is self contained within one .do file.
3. **Estimated Run Time:** On supercomputer, full program run takes about 1.5 hours. Off the supercomputing network expect extensive processing time. 

## List of Tables and Figures
| Exhibit | Script | Output File |
| :--- | :--- | :--- |
| Table 1 | Derived from SIL Policy file. Non-Data
| Table 2 | Derived from SIL Policy file. Non-Data
| Table 3 | `allinshearing_2026.Publication.do` | Lines 978-1058|
| Table 4 | `allinshearing_2026.Publication.do` | Lines 1282-1291|
| Figure 1 | `allinshearing_2026.Publication.do` | Lines 447-448, 479-480, 516-517, 550-551, 716-717, 748-749. 781-782 |
| eTable 1 | `allinshearing_2026.Publication.do` | Lines 354, 651 |
| eTable 2 | `allinshearing_2026.Publication.do` | Lines 113-114|
| eTable 3 | `allinshearing_2026.Publication.do` | Lines  |

## Contact
For questions regarding this replication package, contact [Austin Landini] at [Austin.Landini@gmail.com].
