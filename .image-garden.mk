# SPDX-FileCopyrightText: Canonical Ltd.
# SPDX-License-Identifier: Apache-2.0

define UBUNTU_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
- snap wait system seed.loaded
- snap install gemma4 --beta
packages:
- snapd
endef

define DEBIAN_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
- snap wait system seed.loaded
- snap install core24
- snap install gemma4 --beta
packages:
- snapd
endef

define FEDORA_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
- snap wait system seed.loaded
- snap install core24
- snap install gemma4 --beta
- ln -s /var/lib/snapd/snap /snap
packages:
- snapd
endef
