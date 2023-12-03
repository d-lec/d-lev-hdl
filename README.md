# d-lev-hdl
This is a source mirror of the SystemVerilog source code for the D-Lev processor, sourced from the [D-Lev open source page](http://d-lev.com/source/d-lev_fpga_source_2023-06-23.zip).  
Original documentation is currently located in:  
`README.txt` (sorry, lol)  
`REGS.txt`  
`CHANGE_LOG.txt`  

# Instructions for use
For guaranteed compatibility, compile with Quartus Prime 20.1.0 Lite Edition. Later versions of Quartus have been observed to work without issue.  
The actual Quartus project is `Q20_v0.9.4/ep4ce6e22c8_demo_board.qpf`.  
Output files that can be flashed to an FPGA end in `.sof` (initial RAM image) and `.jic` (SPI flash payload).
For quick reference, the specific part number used on the original D-Lev is a Cyclone IV E - EP4CE6E22C8N.  
Note that the `.mif` files included in this repository are Hive bytecode generated from [d-lev-software](https://github.com/d-lec/d-lev-software).

# yosys / ECP5 port
This is a work in progress and any advice is appreciated.  
One should simply be able to run `make` from the `yosys` directory on any machine with [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) and [sv2v](https://github.com/zachjs/sv2v) installed and configured.  

# Repo conventions
"Original text" for this repo can be found at http://d-lev.com/source/d-lev_fpga_source_[RELEASE_DATE_YYYY-MM-DD].zip. When mirroring an update from the official D-Lev website, switch to the `eric-original` branch, make a "git tag" corresponding to the release date, and upload the original zip file from the website to the Releases page.  
The `.gitignore` for this repo may be a bit overzealous. Quartus spits out a lot of build artifacts and log files, and I've tried to exclude many as possible.  
If I've done my job correctly here, compiling the project in Quartus should result in no change to any tracked source files.
