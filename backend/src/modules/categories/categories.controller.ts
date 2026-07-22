import { Controller, Get, Post, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { CategoriesService } from './categories.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { Role } from '@prisma/client';

@ApiTags('Categories')
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'List all active categories' })
  findAll() {
    return this.categoriesService.findActive();
  }

  @ApiBearerAuth('supabase-jwt')
  @UseGuards(SupabaseAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  @Post()
  @ApiOperation({ summary: 'Create service category (admin)' })
  create(@Body() body: { name: string; icon?: string; description?: string }) {
    return this.categoriesService.create(body);
  }

  @ApiBearerAuth('supabase-jwt')
  @UseGuards(SupabaseAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  @Patch(':id')
  @ApiOperation({ summary: 'Update service category (admin)' })
  update(
    @Param('id') id: string,
    @Body() body: { name?: string; icon?: string; description?: string; isActive?: boolean },
  ) {
    return this.categoriesService.update(id, body);
  }
}
