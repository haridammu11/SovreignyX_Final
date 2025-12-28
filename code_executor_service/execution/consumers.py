import json
from channels.generic.websocket import AsyncWebsocketConsumer

class ProctorConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.session_id = self.scope['url_route']['kwargs']['session_id']
        self.group_name = f'proctor_{self.session_id}'

        # Join session group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        # Leave session group
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    async def receive(self, text_data=None, bytes_data=None):
        """
        Receive frame from student and broadcast to proctor group.
        Handles both Text (JSON) and Binary data.
        """
        if bytes_data:
            # Broadcast binary frame directly for performance
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'video_frame',
                    'data': bytes_data,
                    'is_binary': True
                }
            )
        elif text_data:
            data = json.loads(text_data)
            # Re-broadcast JSON events (TAB_SWITCH, etc)
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'proctor_event',
                    'data': data
                }
            )

    async def video_frame(self, event):
        # Send binary frame to proctor
        await self.send(bytes_data=event['data'])

    async def proctor_event(self, event):
        # Send JSON event to proctor
        await self.send(text_data=json.dumps(event['data']))
