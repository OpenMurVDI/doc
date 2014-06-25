# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright 2012 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import re

from oslo.config import cfg
from cloudbaseinit.metadata.services import base as metadata_services_base
from cloudbaseinit.openstack.common import log as logging
from cloudbaseinit.osutils import factory as osutils_factory
from cloudbaseinit.plugins import base
from cloudbaseinit.plugins.windows import userdatautils
from cloudbaseinit.plugins.windows.userdataplugins import factory

opts = [
    cfg.StrOpt('username', default='Admin', help='User to be added to the '
               'system or updated if already existing'),
    cfg.ListOpt('groups', default=['Administrators'], help='List of local '
                'groups to which the user specified in \'username\' will '
                'be added'),
]

CONF = cfg.CONF
CONF.register_opts(opts)

LOG = logging.getLogger(__name__)


class UserDataAdminPasswordPlugin(base.BasePlugin):
    #_PART_HANDLER_CONTENT_TYPE = "text/part-handler"
    #_GZIP_MAGIC_NUMBER = '\x1f\x8b'

    def execute(self, service, shared_data):
        LOG.debug('OpenMurVDI: executing UserDataAdminPassword Plugin from OpenMurVDI Project')
        try:
            user_data = service.get_user_data()
        except metadata_services_base.NotExistingMetadataException:
            LOG.info("OpenMurVDI: can't connect to Metadata service")
            return (base.PLUGIN_EXECUTION_DONE, False)

        if not user_data:
            LOG.info("OpenMurVDI: user_data doesn't exist")
            return (base.PLUGIN_EXECUTION_DONE, False)

        #user_data = self._check_gzip_compression(user_data)

        # We have to check the file structure and the password
        lines = user_data.split('\n')
        regex = re.compile("password: (.+)$")

        password = ''
        for line in lines:
            mo = regex.match(line)
            if mo:
                password = mo.group(1)
                break
        # Password contains the password in user_data
        user_name = CONF.username
        #LOG.debug("OpenMurVDI: setting password '" + password + "' to user '" + user_name + "'")
        LOG.debug("OpenMurVDI: setting password from user_data to user '" + user_name + "'")

        osutils = osutils_factory.get_os_utils()
        osutils.set_user_password(user_name, password)

        return (base.PLUGIN_EXECUTION_DONE, False)