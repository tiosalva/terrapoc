# Changelog

All notable changes to this project will be documented in this file.

## [3.18.0](https://github.com/terraform-aws-modules/terraform-aws-vpc/compare/v3.17.0...v3.18.0) (2022-10-21)


### Features

* Added ability to specify CloudWatch Log group name for VPC Flow logs ([#847](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/847)) ([80d6318](https://github.com/terraform-aws-modules/terraform-aws-vpc/commit/80d631884126075e1adbe2d410f46ef6b9ea8a19))


### Bug Fixes

* Prevent an error when VPC Flow log log_group and role is not created ([#844](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/844)) ([b0c81ad](https://github.com/terraform-aws-modules/terraform-aws-vpc/commit/b0c81ad61214069f8fa6d35492716c9d4cac9096))

<a name="v3.4.0"></a>
## [v3.4.0] - 2021-08-13

- fix: Update the terraform to support new provider signatures ([#678](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/678))


<a name="v3.3.0"></a>
## [v3.3.0] - 2021-08-10

- docs: Added ID of aws_vpc_dhcp_options to outputs ([#669](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/669))
- fix: Fixed mistake in separate private route tables example ([#664](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/664))


<a name="v3.2.0"></a>
## [v3.2.0] - 2021-06-28

- feat: Added database_subnet_group_name variable ([#656](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/656))


<a name="v3.1.0"></a>
## [v3.1.0] - 2021-06-07

- chore: Removed link to cloudcraft

<a name="v3.0.0"></a>
## [v3.0.0] - 2021-04-26

- refactor: remove existing vpc endpoint configurations from base module and move into sub-module ([#635](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/635))

<a name="v2.14.0"></a>
## [v2.14.0] - 2019-09-03

- Added support for EC2 ClassicLink ([#322](https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/322))

<a name="v1.0.0"></a>
## v1.0.0 - 2022-10-25

- Updated README
- Updated README
- First Module Version
- Added descriptions, applied fmt
- Removed parts of readme
- Initial commit
- Initial commit