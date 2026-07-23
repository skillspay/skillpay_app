import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
} from '@nestjs/swagger';
import { Role, UserStatus } from '@prisma/client';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { FindUsersDto } from './dto/find-users.dto';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { PaginationDto } from '../../common/dto/pagination.dto';

@ApiTags('Users')
@ApiBearerAuth('supabase-jwt')
@UseGuards(SupabaseAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.SUPER_ADMIN)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'List all users (admin)' })
  @ApiQuery({ name: 'role', enum: Role, required: false })
  @ApiQuery({ name: 'status', enum: UserStatus, required: false })
  findAll(@Query() query: FindUsersDto) {
    return this.usersService.findAll(query, query.role, query.status);
  }

  @Get('stats')
  @ApiOperation({ summary: 'User statistics' })
  getStats() {
    return this.usersService.getStats();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update user' })
  update(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.usersService.update(id, dto);
  }

  @Patch(':id/suspend')
  @ApiOperation({ summary: 'Suspend a user' })
  suspend(@Param('id') id: string) {
    return this.usersService.suspend(id);
  }

  @Patch(':id/ban')
  @ApiOperation({ summary: 'Ban a user' })
  ban(@Param('id') id: string) {
    return this.usersService.ban(id);
  }

  @Patch(':id/activate')
  @ApiOperation({ summary: 'Reactivate a user' })
  activate(@Param('id') id: string) {
    return this.usersService.activate(id);
  }
}
