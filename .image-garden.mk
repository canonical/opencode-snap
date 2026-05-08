# SPDX-FileCopyrightText: Canonical Ltd.
# SPDX-License-Identifier: Apache-2.0

define DEBIAN_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
- snap wait system seed.loaded
- snap install core24
packages:
- snapd
endef

define FEDORA_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
- snap wait system seed.loaded
- snap install core24
- ln -s /var/lib/snapd/snap /snap
packages:
- snapd
endef
